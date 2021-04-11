SECTION "Header", ROM0[$0100]

    di
    jp      EntryPoint
    
    DS      $0150 - @, 0
