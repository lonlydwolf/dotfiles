update-programs() {
    # Default variable states
    local dry_run_mode=false
    local quiet_mode=false
    local validate_mode=false

    # Argument Parsing
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -d|--dry) dry_run_mode=true ;;
            -q|--quiet) quiet_mode=true ;;
            -v|--validate) validate_mode=true ;;
            -h|--help)
                echo "Usage: update-programs [options]"
                echo ""
                echo "Options:"
                echo "  -d, --dry       Check for available updates without installing (Dry run)"
                echo "  -q, --quiet     Run silently (suppress standard output)"
                echo "  -v, --validate  Ask for confirmation before updating each app"
                echo "  -h, --help      Show this help message"
                return 0
                ;;
            *) echo "Unknown parameter passed: $1"; return 1 ;;
        esac
        shift
    done

    # Helper function for logging (respects quiet mode)
    log_info() {
        if [[ "$quiet_mode" == false ]]; then
            echo "$@"
        fi
    }

    # Helper to run commands (respects quiet mode)
    # Uses &> to silence both stdout and stderr
    run_cmd() {
        if [[ "$quiet_mode" == true ]]; then
            "$@" &> /dev/null
        else
            "$@"
        fi
    }

    # ---------------------------------------------------------
    # 1. HOMEBREW UPDATE
    # ---------------------------------------------------------
    log_info "🔄 Fetching Homebrew updates..."
    if run_cmd brew update; then
        log_info "✓ Homebrew definition updated"
    fi

    # ---------------------------------------------------------
    # 2. DRY RUN MODE (-d)
    # ---------------------------------------------------------
    if [[ "$dry_run_mode" == true ]]; then
        echo "\n📦 --- Available Homebrew Updates ---"
        brew outdated --greedy-auto-updates
        
        if command -v mas &> /dev/null; then
            echo "\n🍎 --- Available App Store Updates ---"
            mas outdated
        fi

        if command -v npm &> /dev/null; then
            echo "\n📦 --- Available NPM Global Updates ---"
            npm outdated -g --depth=0
        fi
        return 0
    fi

    # ---------------------------------------------------------
    # 3. HOMEBREW UPGRADE (Validate vs Normal)
    # ---------------------------------------------------------
    log_info "\n🔄 Processing Homebrew packages..."
    
    # Capture outdated list first to handle empty states gracefully
    local brew_outdated_output=$(brew outdated --greedy-auto-updates)

    if [[ -z "$brew_outdated_output" ]]; then
        log_info "✓ All Homebrew packages are up-to-date"
    else
        if [[ "$validate_mode" == true ]]; then
            # Use the captured output to avoid running outdated twice
            local outdated_brews=("${(@f)$(echo "$brew_outdated_output" | awk '{print $1}')}")
            
            for formula in $outdated_brews; do
                # Skip empty lines just in case
                [[ -z "$formula" ]] && continue

                # Ask user for confirmation (read -q is Zsh specific for y/n)
                echo -n "Update $formula? [y/N] "
                if read -q; then
                    echo # print newline after keypress
                    run_cmd brew upgrade --greedy-auto-updates "$formula"
                else
                    echo "\nSkipping $formula"
                fi
            done
        else
            # Normal Update
            run_cmd brew upgrade --greedy-auto-updates
        fi
    fi

    # ---------------------------------------------------------
    # 4. CLEANUP
    # ---------------------------------------------------------
    log_info "\n🧹 Cleaning up..."
    if [[ "$quiet_mode" == true ]]; then
         brew cleanup --prune=all &> /dev/null
    else
         # Pipes to sed to remove the long path prefix
         brew cleanup --prune=all | sed "s|$HOME/Library/Caches/Homebrew/||g"
    fi
    log_info "✓ Cleanup complete"
    
    # ---------------------------------------------------------
    # 5. MAS UPDATE (Validate vs Normal)
    # ---------------------------------------------------------
    log_info "\n🔄 Processing App Store..."
    
    if ! command -v mas &> /dev/null; then
        log_info "⚠️  mas is not installed, skipping."
    else
        # Check outdated first to handle empty states and "All good" messages
        local mas_outdated_output=$(mas outdated)

        if [[ -z "$mas_outdated_output" ]]; then
            log_info "✓ All App Store apps are up-to-date"
        else
            if [[ "$validate_mode" == true ]]; then
                # Split output by newline into array
                local outdated_mas=("${(@f)mas_outdated_output}")
                
                for line in "$outdated_mas"; do
                    # Parse ID and Name
                    local app_id=$(echo "$line" | awk '{print $1}')
                    local app_name=$(echo "$line" | cut -d' ' -f2-)
                    
                    # Safety check: ensure we have an ID
                    if [[ -z "$app_id" ]]; then continue; fi

                    echo -n "Update $app_name? [y/N] "
                    if read -q; then
                        echo 
                        run_cmd mas upgrade "$app_id"
                    else
                        echo "\nSkipping $app_name"
                    fi
                done
            else
                # Normal Update
                run_cmd mas upgrade
                log_info "✓ App Store updates complete"
            fi
        fi
    fi

    # ---------------------------------------------------------
    # 6. NPM UPDATE (Validate vs Normal)
    # ---------------------------------------------------------
    log_info "\n🔄 Processing NPM Global Packages..."
    
    if ! command -v npm &> /dev/null; then
        log_info "⚠️  npm is not installed, skipping."
    else
        # Check outdated first to handle empty states
        # --parseable gives easy-to-parse format, --depth=0 keeps it top-level
        local npm_outdated_output=$(npm outdated -g --parseable --depth=0)

        if [[ -z "$npm_outdated_output" ]]; then
            log_info "✓ All global NPM packages are up-to-date"
        else
            if [[ "$validate_mode" == true ]]; then
                # Split output by newline into array
                local outdated_npm=("${(@f)npm_outdated_output}")
                
                for line in "$outdated_npm"; do
                    # Format: /path/to/lib/node_modules/PKGNAME:current:wanted:latest
                    # Extract PKGNAME from the path (first field)
                    local pkg_path=$(echo "$line" | cut -d: -f1)
                    local pkg_name=$(basename "$pkg_path")
                    
                    if [[ -z "$pkg_name" ]]; then continue; fi

                    echo -n "Update $pkg_name? [y/N] "
                    if read -q; then
                        echo 
                        run_cmd npm install -g "$pkg_name@latest"
                    else
                        echo "\nSkipping $pkg_name"
                    fi
                done
            else
                # Normal Update
                # npm update -g outputs the tree of updated packages by default
                run_cmd npm update -g
                log_info "✓ NPM global updates complete"
            fi
        fi
    fi

    log_info "\n✅ All operations complete!"
}
