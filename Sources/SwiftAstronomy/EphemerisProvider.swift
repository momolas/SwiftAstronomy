//
//  EphemerisProvider.swift
//  SwiftAstronomy
//
//  Created for SwiftAstronomy.
//  MIT Licence. See LICENCE file.
//

import Foundation

// MARK: - Errors

/// Errors that can occur when computing ephemeris positions.
public enum EphemerisError: Error, Sendable {
    /// The requested body is not supported by this provider.
    case bodyNotSupported(SolarSystemBody)
    /// The Julian Day is outside the valid range for this provider.
    case dateOutOfRange(JulianDay)
    /// A required data file could not be found at the expected path.
    case dataFileNotFound(String)
    /// A data file exists but is corrupted or has an unexpected format.
    case dataCorrupted(String)
}

// MARK: - Protocol

/// Abstraction for ephemeris computation engines of varying precision.
///
/// Conforming types provide heliocentric positions and state vectors for Solar System bodies.
/// Three built-in providers are available:
/// - ``AnalyticalEphemerisProvider``: Zero-dependency default using VSOP87 + ELP2000 (≈100 m accuracy).
/// - ``VSOP2013Provider``: High-precision planetary positions from IMCCE VSOP2013 (≈1–10 m accuracy).
/// - ``HybridEphemerisProvider``: Combines VSOP2013 (planets) with JPL DE440 (Moon, ≈1–3 cm accuracy).
///
/// All positions are returned in the **ICRS/J2000** reference frame with units of **AU** for position
/// and **AU/day** for velocity.
public protocol EphemerisProvider: Sendable {
    /// Heliocentric position of a Solar System body in AU (ICRS/J2000).
    ///
    /// - Parameters:
    ///   - body: The target Solar System body.
    ///   - jd: The epoch expressed as a Julian Day (TDB).
    /// - Returns: Heliocentric position vector in astronomical units.
    /// - Throws: ``EphemerisError`` if the body is unsupported or the date is out of range.
    func position(for body: SolarSystemBody, at jd: JulianDay) throws -> Vector3D

    /// Full 6D state vector (position + velocity) of a Solar System body (ICRS/J2000).
    ///
    /// - Parameters:
    ///   - body: The target Solar System body.
    ///   - jd: The epoch expressed as a Julian Day (TDB).
    /// - Returns: State vector with position in AU and velocity in AU/day.
    /// - Throws: ``EphemerisError`` if the body is unsupported or the date is out of range.
    func stateVector(for body: SolarSystemBody, at jd: JulianDay) throws -> StateVector
}
