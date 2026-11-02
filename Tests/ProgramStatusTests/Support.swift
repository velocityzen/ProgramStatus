/// Wraps a report body the way the encoder frames it with the default ST terminator.
func osc(_ body: String) -> String {
    "\u{1B}]7501;\(body)\u{1B}\\"
}
