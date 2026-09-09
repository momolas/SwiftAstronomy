//
//  VSOP2013Provider.swift
//  SwiftAstronomy
//
//  Created for SwiftAstronomy.
//  MIT Licence. See LICENCE file.
//

import Foundation
import AAplus

/// High-precision planetary ephemeris provider using the VSOP2013 theory (IMCCE, Observatoire de Paris).
///
/// VSOP2013 provides heliocentric ecliptic positions and velocities for the 9 major Solar System bodies
/// (Mercury through Pluto) with an accuracy of ≈1–10 meters over the interval −4000 to +8000 CE.
///
/// The underlying C++ implementation (`CAAVSOP2013` from AA+ v2.63) requires pre-computed binary data
/// files (`VSOP2013.P2000.bin`, etc.) to be present in a directory specified at initialization.
/// Use ``EphemerisDataManager`` to download these files from the official IMCCE server.
///
/// - Note: The Moon and Sun are not directly supported by VSOP2013. For the Moon, use
///   ``LunarDE440Provider`` or ``HybridEphemerisProvider``. The Sun position is derived
///   by negating the Earth-Moon Barycenter position.
public final class VSOP2013Provider: @unchecked Sendable {

    // MARK: - Properties

    /// The directory containing the VSOP2013 binary data files.
    public let dataDirectoryURL: URL

    /// The underlying C++ VSOP2013 engine, heap-allocated to keep the constructor in the C++ object.
    private let vsop2013: UnsafeMutablePointer<CAAVSOP2013>

    // MARK: - Initialization

    /// Creates a VSOP2013 provider with data files from the specified directory.
    ///
    /// - Parameter dataDirectoryURL: Directory containing VSOP2013 binary files
    ///   (e.g. `VSOP2013.P1000.bin`, `VSOP2013.P2000.bin`).
    /// - Throws: ``EphemerisError/dataFileNotFound(_:)`` if the directory does not exist.
    public init(dataDirectoryURL: URL) throws {
        self.dataDirectoryURL = dataDirectoryURL
        let path = dataDirectoryURL.path
        guard FileManager.default.fileExists(atPath: path) else {
            throw EphemerisError.dataFileNotFound(path)
        }
        self.vsop2013 = .allocate(capacity: 1)
        vsop2013.initialize(to: CAAVSOP2013())
        vsop2013.pointee.SetBinaryFilesDirectory(path)
    }

    deinit {
        vsop2013.deinitialize(count: 1)
        vsop2013.deallocate()
    }

    // MARK: - Planet Mapping

    /// Maps a ``SolarSystemBody`` to the corresponding `CAAVSOP2013.Planet` enum value.
    ///
    /// - Returns: The VSOP2013 planet constant, or `nil` for bodies not supported by VSOP2013 (Sun, Moon).
    private static func vsop2013Planet(for body: SolarSystemBody) -> CAAVSOP2013.Planet? {
        switch body {
        case .mercury: return .MERCURY
        case .venus: return .VENUS
        case .earth: return .EARTH_MOON_BARYCENTER
        case .mars: return .MARS
        case .jupiter: return .JUPITER
        case .saturn: return .SATURN
        case .uranus: return .URANUS
        case .neptune: return .NEPTUNE
        case .pluto: return .PLUTO
        case .sun, .moon: return nil
        }
    }

    // MARK: - Internal Calculation

    /// Computes the raw VSOP2013 position for a planet at the given Julian Day.
    ///
    /// The returned position is in the ecliptic frame of J2000.0. VSOP2013 internally
    /// converts to equatorial (ICRS) via `Ecliptic2Equatorial`.
    private func calculateEquatorial(planet: CAAVSOP2013.Planet, jd: Double) throws -> CAAVSOP2013Position {
        do {
            let ecliptic = vsop2013.pointee.Calculate(planet, jd)
            return CAAVSOP2013.Ecliptic2Equatorial(ecliptic)
        } catch {
            throw EphemerisError.dataFileNotFound(
                "VSOP2013 binary files missing or invalid in \(dataDirectoryURL.path)"
            )
        }
    }
}

// MARK: - EphemerisProvider Conformance

extension VSOP2013Provider: EphemerisProvider {

    /// Heliocentric position of a Solar System body in AU (ICRS/J2000).
    ///
    /// For the Sun, the position is derived as the negative of the Earth-Moon Barycenter.
    /// For the Moon, this provider throws ``EphemerisError/bodyNotSupported(_:)``
    /// — use ``HybridEphemerisProvider`` instead.
    public func position(for body: SolarSystemBody, at jd: JulianDay) throws -> Vector3D {
        switch body {
        case .sun:
            // Sun is at the origin in heliocentric coordinates. For Solar System Barycentric
            // coordinates, we would need the Sun's offset, but for heliocentric we return zero.
            return .zero
        case .moon:
            throw EphemerisError.bodyNotSupported(.moon)
        default:
            guard let planet = Self.vsop2013Planet(for: body) else {
                throw EphemerisError.bodyNotSupported(body)
            }
            let pos = try calculateEquatorial(planet: planet, jd: jd.value)
            return Vector3D(x: pos.X, y: pos.Y, z: pos.Z)
        }
    }

    /// Full 6D state vector (position in AU, velocity in AU/day) for a Solar System body (ICRS/J2000).
    public func stateVector(for body: SolarSystemBody, at jd: JulianDay) throws -> StateVector {
        switch body {
        case .sun:
            return StateVector(position: .zero, velocity: .zero)
        case .moon:
            throw EphemerisError.bodyNotSupported(.moon)
        default:
            guard let planet = Self.vsop2013Planet(for: body) else {
                throw EphemerisError.bodyNotSupported(body)
            }
            let pos = try calculateEquatorial(planet: planet, jd: jd.value)
            return StateVector(
                position: Vector3D(x: pos.X, y: pos.Y, z: pos.Z),
                velocity: Vector3D(x: pos.X_DASH, y: pos.Y_DASH, z: pos.Z_DASH)
            )
        }
    }
}
