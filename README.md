# POSA Offline Data

Versioned offline map and point-of-interest packages for POSA.

Each state package contains:

- Mapsforge v5 map data
- Mapsforge POI v3 search data
- A machine-readable manifest with file sizes and SHA-256 checksums

Packages are published as GitHub release assets so they can be downloaded without an account. The current collection covers all 50 U.S. states and the District of Columbia.

## Data license and attribution

The packaged geographic data is derived from OpenStreetMap and is made available under the Open Database License 1.0.

© OpenStreetMap contributors

- [OpenStreetMap copyright and attribution](https://www.openstreetmap.org/copyright)
- [Open Database License 1.0](https://opendatacommons.org/licenses/odbl/1-0/)

## Safety notice

Mapped data does not prove current access, conditions, availability, potability, operating hours, or route safety. Verify critical information through authoritative local sources whenever possible.

## Website

Browse and download packages at [unpluggedai.io/posa/data](https://unpluggedai.io/posa/data).

## Release process

The `scripts/publish-state-bundle.sh` helper assembles one state package from a POSA publish plan, records its checksum, and uploads it to the matching GitHub release. Generated archives stay in `.release-work` until the release has been verified.
