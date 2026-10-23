import Testing
import BrewtimeCore

@Test(arguments: [
    (0, "0s"),
    (59, "59s"),
    (60, "1m 00s"),
    (303, "5m 03s"),
    (3_599, "59m 59s"),
    (3_600, "1h 00m"),
    (7_500, "2h 05m"),
    (86_399, "23h 59m"),
    (86_400, "1d 0h"),
    (97_200, "1d 3h"),
])
func formatsSeconds(seconds: Int, expected: String) {
    #expect(DurationFormat.string(fromSeconds: seconds) == expected)
}

@Test(arguments: [-1, -3_600, Int.min])
func clampsNegativeInputToZero(seconds: Int) {
    #expect(DurationFormat.string(fromSeconds: seconds) == "0s")
}
