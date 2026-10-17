package main

import (
	"encoding/csv"
	"encoding/hex"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	innoextract "github.com/Peiratooo/innoextract-go"
	"github.com/Peiratooo/innoextract-go/internal/format"
	"github.com/Peiratooo/innoextract-go/internal/setup"
)

func die(err error) {
	fmt.Fprintf(os.Stderr, "error: %v\n", err)
	os.Exit(2)
}

func openArchive(path string) (*os.File, *innoextract.Archive, *format.Archive, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, nil, nil, err
	}
	arch, err := innoextract.Open(f)
	if err != nil {
		f.Close()
		return nil, nil, nil, err
	}
	// Re-parse through internal setup to reach the extra header fields we patched in.
	raw, err := setup.Parse(f, setup.Options{})
	if err != nil {
		f.Close()
		return nil, nil, nil, err
	}
	return f, arch, raw, nil
}

func cmdInfo(path string) int {
	f, arch, raw, err := openArchive(path)
	if err != nil {
		die(err)
	}
	defer f.Close()
	info := arch.Info()
	h := raw.Header
	fmt.Println("== Setup metadata ==")
	fmt.Printf("DataVersion: %s\n", info.DataVersion)
	fmt.Printf("AppName: %s\n", info.AppName)
	fmt.Printf("AppVersion: %s\n", info.AppVersion)
	fmt.Printf("AppId: %s\n", info.AppID)
	fmt.Printf("Publisher: %s\n", info.Publisher)
	fmt.Printf("BaseFilename: %s\n", h.BaseFilename)
	fmt.Printf("DefaultDirName: %s\n", h.DefaultDirName)
	fmt.Printf("DefaultGroupName: %s\n", h.DefaultGroupName)
	fmt.Printf("LicenseFile: %s\n", h.LicenseFile)
	fmt.Printf("InfoFile: %s\n", h.InfoFile)
	fmt.Printf("ExtraHeaderFile: %s\n", h.ExtraHeaderFile)
	fmt.Printf("Encrypted: %v\n", h.Encrypted)
	fmt.Printf("Compression: %v\n", h.Compression)
	fmt.Printf("CompiledCodeLength: %d\n", len(h.CompiledCodeText))
	fmt.Printf("Messages: %d\n", len(raw.Messages))
	fmt.Printf("Languages: %d\n", len(raw.Languages))
	for _, l := range raw.Languages {
		fmt.Printf("  lang: %s (%s) id=%d cp=%d\n", l.Name, l.DisplayName, l.ID, l.Codepage)
	}
	fmt.Printf("FileEntries: %d\n", len(raw.Files))
	fmt.Printf("DataEntries: %d\n", len(raw.DataEntries))
	fmt.Printf("RegistryEntries: %d\n", len(raw.Registry))
	if len(raw.Messages) > 0 {
		fmt.Println("== Custom messages ==")
		for _, m := range raw.Messages {
			fmt.Printf("  %s = %s\n", m.Key, m.Value)
		}
	}
	return 0
}

func openFiles(path string) (*os.File, []format.FileEntry, *format.Header, int) {
	f, err := os.Open(path)
	if err != nil {
		die(err)
	}
	raw, err := setup.Parse(f, setup.Options{})
	if err != nil {
		die(err)
	}
	return f, raw.Files, &raw.Header, 0
}

func cmdList(path string) int {
	f, files, h, _ := openFiles(path)
	defer f.Close()
	fmt.Fprintf(os.Stderr, "header: DefaultDir=%s DefaultGroup=%s License=%s Info=%s CompiledCodeLen=%d\n", h.DefaultDirName, h.DefaultGroupName, h.LicenseFile, h.InfoFile, len(h.CompiledCodeText))
	w := csv.NewWriter(os.Stdout)
	w.Comma = '\t'
	w.Write([]string{"#", "destination", "source", "size", "location", "langs", "components", "tasks", "check", "temp", "bits32", "bits64", "dontcopy", "beforeinstall", "afterinstall"})
	for i, fe := range files {
		w.Write([]string{
			fmt.Sprintf("%d", i),
			fe.Destination, fe.Source,
			fmt.Sprintf("%d", fe.Size),
			fmt.Sprintf("%d", fe.Location),
			fe.Languages, fe.Components, fe.Tasks, fe.Check,
			fmt.Sprintf("%v", fe.Temporary),
			fmt.Sprintf("%v", fe.Bits32),
			fmt.Sprintf("%v", fe.Bits64),
			fmt.Sprintf("%v", fe.DontCopy),
			fe.BeforeInstall, fe.AfterInstall,
		})
	}
	w.Flush()
	fmt.Fprintf(os.Stderr, "file entries: %d, data entries listed below\n", len(files))
	return 0
}

func cmdExtract(path, outdir string) int {
	f, err := os.Open(path)
	if err != nil {
		die(err)
	}
	defer f.Close()
	arch, err := innoextract.Open(f)
	if err != nil {
		die(err)
	}
	files, xerr := arch.Extract()
	if files == nil && xerr != nil {
		die(xerr)
	}
	if err := os.MkdirAll(outdir, 0o755); err != nil {
		die(err)
	}
	manifest, err := os.Create(filepath.Join(outdir, "_manifest.tsv"))
	if err != nil {
		die(err)
	}
	defer manifest.Close()
	fmt.Fprintln(manifest, "index\tclean_path\tsize\tsha256")
	seen := map[string]int{}
	for _, file := range files {
		rel := file.Path
		if rel == "" {
			rel = fmt.Sprintf("_unnamed_%d.bin", file.Entry.Index)
		}
		if n, ok := seen[rel]; ok {
			seen[rel] = n + 1
			ext := filepath.Ext(rel)
			rel = strings.TrimSuffix(rel, ext) + fmt.Sprintf("__dup%d", n) + ext
		} else {
			seen[rel] = 0
		}
		dest := filepath.Join(outdir, filepath.FromSlash(rel))
		if err := os.MkdirAll(filepath.Dir(dest), 0o755); err != nil {
			die(err)
		}
		if err := os.WriteFile(dest, file.Data, 0o644); err != nil {
			die(err)
		}
		fmt.Fprintf(manifest, "%d\t%s\t%d\t%s\n", file.Entry.Index, rel, len(file.Data), file.SHA256)
		fmt.Printf("%d\t%s\t%d\t%s\n", file.Entry.Index, rel, len(file.Data), file.SHA256)
	}
	manifest.Sync()
	if xerr != nil {
		fmt.Fprintf(os.Stderr, "extraction completed with errors: %v\n", xerr)
		return 3
	}
	return 0
}

func cmdDump(path, outdir string) int {
	f, files, h, _ := openFiles(path)
	defer f.Close()
	if err := os.MkdirAll(outdir, 0o755); err != nil {
		die(err)
	}
	// header extras
	meta := filepath.Join(outdir, "_setup_header.txt")
	var sb strings.Builder
	fmt.Fprintf(&sb, "DefaultDirName=%s\nDefaultGroupName=%s\nLicenseFile=%s\nInfoFile=%s\nExtraHeaderFile=%s\nCompiledCodeLength=%d\n", h.DefaultDirName, h.DefaultGroupName, h.LicenseFile, h.InfoFile, h.ExtraHeaderFile, len(h.CompiledCodeText))
	os.WriteFile(meta, []byte(sb.String()), 0o644)
	if h.CompiledCodeText != "" {
		os.WriteFile(filepath.Join(outdir, "_compiled_code.txt"), []byte(h.CompiledCodeText), 0o644)
	}
	// raw source strings from file entries
	var sb2 strings.Builder
	for i, fe := range files {
		if fe.Source != "" {
			fmt.Fprintf(&sb2, "%d\tsource=%s\tdest=%s\n", i, fe.Source, fe.Destination)
		}
	}
	os.WriteFile(filepath.Join(outdir, "_source_paths.tsv"), []byte(sb2.String()), 0o644)
	fmt.Printf("dumped header meta + compiled code + source paths to %s\n", outdir)
	return 0
}

func main() {
	if len(os.Args) < 3 {
		fmt.Fprintln(os.Stderr, "usage: innox <info|list|extract|dump|blobs> <setup.exe> [outdir]")
		os.Exit(1)
	}
	cmd := os.Args[1]
	path := os.Args[2]
	var rc int
	switch cmd {
	case "info":
		rc = cmdInfo(path)
	case "list":
		rc = cmdList(path)
	case "extract":
		if len(os.Args) < 4 {
			die(fmt.Errorf("extract requires outdir"))
		}
		rc = cmdExtract(path, os.Args[3])
	case "dump":
		if len(os.Args) < 4 {
			die(fmt.Errorf("dump requires outdir"))
		}
		rc = cmdDump(path, os.Args[3])
	case "blobs":
		if len(os.Args) < 4 {
			die(fmt.Errorf("blobs requires outdir"))
		}
		rc = cmdBlobs(path, os.Args[3])
	default:
		die(fmt.Errorf("unknown command %q", cmd))
	}
	_ = hex.EncodeToString
	os.Exit(rc)
}
func cmdBlobs(path, outdir string) int {
	f, err := os.Open(path)
	if err != nil {
		die(err)
	}
	defer f.Close()
	d, err := setup.DebugParse(f, setup.Options{})
	if err != nil {
		die(err)
	}
	if err := os.MkdirAll(outdir, 0o755); err != nil {
		die(err)
	}
	o := d.Offsets
	fmt.Printf("loader magic found: %v revision: %d\n", o.FoundMagic, o.Revision)
	fmt.Printf("ExeOffset: %d ExeCompressed: %d ExeUncompressed: %d\n", o.ExeOffset, o.ExeCompressedSize, o.ExeUncompressedSize)
	fmt.Printf("HeaderOffset: %d DataOffset: %d\n", o.HeaderOffset, o.DataOffset)
	fmt.Printf("version: %s\n", d.Version.String())
	for k, v := range d.Counts {
		fmt.Printf("count %s = %d\n", k, v)
	}
	fmt.Printf("primary block: %d bytes, secondary block: %d bytes\n", len(d.Primary), len(d.Secondary))
	os.WriteFile(filepath.Join(outdir, "_primary_header.bin"), d.Primary, 0o644)
	os.WriteFile(filepath.Join(outdir, "_secondary_header.bin"), d.Secondary, 0o644)
	fmt.Printf("wrote %s\n", outdir)
	return 0
}
