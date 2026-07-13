//
//  SafePlaceVideoCatalog.swift
//  Heal
//
//  Slice 1: single predefined YouTube Short for Safe Place playback.
//  Manually pre-validated as embeddable. No paging or multi-video logic yet.
//

import Foundation

enum SafePlaceVideoCatalog {
    /// Slice 1 only — one real predefined Short ID.
    /// Source: https://youtube.com/shorts/iw4OS1Ki76g
    /// Validated: oEmbed + embed page resolve; embed iframe available.
    static let slice1VideoID = "iw4OS1Ki76g"
}
