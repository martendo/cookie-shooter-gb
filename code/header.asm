SECTION "Entry Point", ROM0[$0100]

    di
    jp      Initialize
    
    DS      $0150 - @, 0
