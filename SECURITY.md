# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 0.2.x   | :white_check_mark: |
| 0.1.x   | :white_check_mark: |
| < 0.1.0 | :x:                |

## Reporting a Vulnerability

We take the security of IQToolkit Analyzer seriously. If you believe you have found a security vulnerability, please report it to us as described below.

### Please Do Not:
- Open a public GitHub issue for security vulnerabilities
- Disclose the vulnerability publicly before it has been addressed

### Please Do:
1. **Email us directly** at security@iqtoolkit.ai with:
   - A description of the vulnerability
   - Steps to reproduce the issue
   - Potential impact
   - Any suggested fixes (if available)

2. **Provide sufficient information** to reproduce the problem:
   - Version of IQToolkit Analyzer
   - Operating system and version
   - Python version
   - Database type and version (if applicable)
   - Any relevant configuration details

### What to Expect:
- **Initial Response**: We will acknowledge your email within **48 hours**
- **Status Updates**: We will keep you informed about our progress
- **Disclosure Timeline**: We aim to address critical vulnerabilities within **7 days** and provide a patch or workaround
- **Credit**: We will credit you in the release notes (unless you prefer to remain anonymous)

## Security Best Practices

### For Users:

1. **API Keys & Credentials**
   - Never commit API keys or credentials to version control
   - Use environment variables for sensitive data (`OPENAI_API_KEY`, etc.)
   - Review `.gitignore` to ensure sensitive files are excluded

2. **Database Connections**
   - Use secure connection strings with proper authentication
   - Limit database user permissions to read-only access when possible
   - Avoid using production database credentials in development

3. **Log File Security**
   - Database logs may contain sensitive query data
   - Sanitize logs before sharing or uploading
   - Use local Ollama models (v0.2.2+) for maximum privacy with sensitive data

4. **Dependencies**
   - Keep IQToolkit Analyzer updated to the latest version
   - Regularly update Python dependencies: `pip install --upgrade -r requirements.txt`
   - Monitor security advisories for dependencies

5. **Docker Security**
   - Use official images from trusted registries
   - Don't run containers as root (our images use non-root user by default)
   - Scan images for vulnerabilities: `docker scan iqtoolkit/analyzer`

### For Contributors:

1. **Code Review**
   - All code changes require review before merging
   - Security-sensitive changes require additional scrutiny
   - Follow secure coding practices outlined in CONTRIBUTING.md

2. **Dependencies**
   - Vet new dependencies carefully
   - Prefer well-maintained, widely-used packages
   - Check for known vulnerabilities before adding dependencies

3. **Testing**
   - Include security test cases for new features
   - Test input validation and sanitization
   - Verify proper error handling that doesn't leak sensitive information

## Known Security Considerations

### AI Provider Data Privacy

**OpenAI (v0.1.x+ - Supported)**
- Query data is sent to OpenAI's servers for analysis
- Covered by OpenAI's data usage policies
- **Recommendation**: Sanitize sensitive data before analysis or prefer local Ollama (v0.2.2+)

**Ollama (v0.2.2+ - Available)**
- Runs completely locally on your machine
- No data leaves your environment
- **Recommendation**: Use for production data and sensitive queries

### Database Log Contents
- Slow query logs may contain:
  - Table and column names (database schema)
  - Query parameters (potentially sensitive data)
  - User information
  - Application logic patterns

**Mitigation**: Review and sanitize logs before analysis, especially when using cloud AI providers.

## Security Updates

Security updates will be released as:
- **Critical**: Immediate patch release (e.g., 0.2.1 → 0.2.2)
- **High**: Patch release within 7 days
- **Medium**: Included in next minor release
- **Low**: Included in next scheduled release

Subscribe to our [GitHub releases](https://github.com/iqtoolkit/iqtoolkit-analyzer/releases) to stay informed about security updates.

## Vulnerability Disclosure Policy

When we receive a security bug report, we will:

1. Confirm the problem and determine affected versions
2. Audit code to find similar problems
3. Prepare fixes for all supported versions
4. Release new versions as quickly as possible
5. Prominently announce the issue in release notes

## Contact

- **Security Issues**: security@iqtoolkit.ai
- **General Support**: [GitHub Issues](https://github.com/iqtoolkit/iqtoolkit-analyzer/issues)
- **Maintainer**: Giovanni Martinez <gio@iqtoolkit.ai>

## Attribution

We appreciate the security research community and will acknowledge researchers who report vulnerabilities responsibly.

---

**Last Updated**: November 23, 2025
