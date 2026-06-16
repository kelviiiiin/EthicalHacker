# HTTP Headers Scanner

A command-line tool that sends HTTP requests to a target server and grades its security posture based on the security-related headers returned in the HTTP response.

## How It Works

The scanner checks the response for **six security headers**, each assigned a severity level: `high`, `medium`, or `low`. Each severity maps to a point value:

| Severity | Points |
|----------|--------|
| High     | 30     |
| Medium   | 15     |
| Low      | 5      |

For each header, the scanner produces one of three findings:

| Finding   | Points Earned                  |
|-----------|---------------------------------|
| `ok`      | Full point value for that header |
| `weak`    | Half the point value             |
| `missing` | Zero points                      |

## Scoring

The overall score is calculated as a percentage of the total possible points:

```
score = round((earned points / total points) * 100)
```

This score is then converted into a letter grade using the following cutoffs:

| Score Range | Grade |
|-------------|-------|
| >= 90       | A     |
| >= 80       | B     |
| >= 70       | C     |
| >= 60       | D     |
| < 60        | F     |

## Usage

```bash
# Example usage
python3 http_headers_scanner.py <target-url>
```

## Example Output

```
Target: https://example.com

Header                      Severity   Result    Points
Content-Security-Policy     High       ok        30/30
Strict-Transport-Security   High       missing   0/30
X-Frame-Options              Medium     weak      7.5/15
X-Content-Type-Options       Medium     ok        15/15
Referrer-Policy               Low        ok        5/5
Permissions-Policy            Low        missing   0/5

Total: 57.5/100
Score: 58
Grade: F
```
