# Contributing Guidelines

Thank you for your interest in contributing to Aether Drone! This document provides guidelines and instructions for contributing to the project.

**Quick Links:** [Code of Conduct](#code-of-conduct) | [Getting Started](#getting-started) | [Development Setup](#development-setup) | [Making Changes](#making-changes) | [Submitting Changes](#submitting-changes) | [Coding Standards](#coding-standards) | [Testing](#testing) | [Back to Main Docs](../README.md)

**Table of Contents**

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Submitting Changes](#submitting-changes)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
  - [TypeScript](#typescript)
  - [React/Next.js](#reactnextjs)
  - [Terraform](#terraform)
  - [Python (Lambda)](#python-lambda)
  - [CSS/Tailwind](#csstailwind)
- [Commit Conventions](#commit-conventions)
- [Testing](#testing)
- [Documentation](#documentation)
- [Areas for Contribution](#areas-for-contribution)
- [License](#license)
- [Getting Help](#getting-help)
- [Quick Reference](#quick-reference)
- [Summary](#summary)

---

## Code of Conduct

### Our Commitment

We are committed to providing a welcoming and inspiring community for all. Please read and adhere to our Code of Conduct.

### Expected Behavior

✅ **Do:**

- Be respectful and inclusive
- Use welcoming and inclusive language
- Be patient with other contributors
- Focus on constructive feedback
- Respect differing opinions and experiences
- Help others learn and grow

❌ **Don't:**

- Use offensive or exclusionary language
- Engage in harassment or discrimination
- Make personal attacks
- Share others' private information without consent
- Spam or self-promote excessively
- Post content that violates intellectual property

### Reporting Issues

If you witness or experience violations:

1. Report to project maintainers immediately
2. Include specific details and context
3. Be respectful and factual
4. Avoid public calls-out (use private channels)

---

## Getting Started

### Prerequisites

Before contributing, ensure you have:

- **Git** - Version control
- **Node.js 18+** - JavaScript runtime
- **Terraform 1.0+** - Infrastructure as code
- **AWS Account** - For infrastructure testing
- **GitHub Account** - For pull requests

### Fork & Clone Repository

```bash
# 1. Fork on GitHub
# Go to https://github.com/yourusername/aether-drone
# Click "Fork" button (top right)

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/aether-drone.git
cd aether-drone

# 3. Add upstream remote
git remote add upstream https://github.com/ORIGINAL_OWNER/aether-drone.git

# 4. Verify remotes
git remote -v
# origin → your fork
# upstream → original repository
```

### Verify Your Setup

```bash
# Verify Git
git --version

# Verify Node.js
node --version
npm --version

# Verify Terraform
terraform version

# Verify AWS CLI
aws --version

# Verify AWS credentials
aws sts get-caller-identity
```

---

## Development Setup

### Local Environment

```bash
# 1. Install dependencies
npm install

# 2. Start development server
npm run dev

# 3. Open browser
# Visit: http://localhost:3000

# 4. Make changes and see live reload
# Edit app/page.tsx and changes appear immediately
```

### Environment Variables

Create `.env.local` (not committed to git):

```bash
# .env.local (create this file)
NEXT_PUBLIC_API_URL=http://localhost:3000
```

For AWS infrastructure testing:

```bash
# Configure AWS credentials
aws configure

# Verify
aws sts get-caller-identity
```

### Project Structure

```
aether-drone/
├── app/                    # Next.js application
│   ├── page.tsx           # Main page component
│   ├── layout.tsx         # Root layout
│   └── globals.css        # Global styles
│
├── public/                # Static assets
│   └── aether_drone.png   # Images
│
├── terraform/             # Infrastructure code
│   ├── main.tf           # Primary resources
│   ├── variables.tf      # Input variables
│   ├── outputs.tf        # Output values
│   └── README.md         # Terraform docs
│
├── .github/workflows/     # CI/CD automation
│   ├── deploy-app.yml    # Application deployment
│   └── deploy-infra.yml  # Infrastructure deployment
│
├── docs/                 # Documentation
│   ├── ARCHITECTURE.md
│   ├── CI-CD.md
│   ├── DEPLOYMENT.md
│   └── TROUBLESHOOTING.md
│
├── package.json          # Node.js dependencies
├── tailwind.config.js    # Tailwind CSS config
├── tsconfig.json         # TypeScript config
└── README.md             # Project overview
```

---

## Making Changes

### Branch Naming Convention

Use descriptive branch names:

```bash
# Feature branch
git checkout -b feature/add-dark-mode

# Bug fix branch
git checkout -b fix/location-header-parsing

# Documentation branch
git checkout -b docs/update-deployment-guide

# Infrastructure branch
git checkout -b infra/increase-lambda-memory

# Naming format: type/short-description
```

### Types of Changes

Choose the appropriate type:

| Type | Example | When to Use |
|------|---------|------------|
| `feature/` | `feature/add-search` | New functionality |
| `fix/` | `fix/header-parsing` | Bug fixes |
| `docs/` | `docs/update-readme` | Documentation only |
| `refactor/` | `refactor/optimize-lambda` | Code improvement |
| `perf/` | `perf/reduce-bundle` | Performance optimization |
| `test/` | `test/add-unit-tests` | Testing additions |
| `infra/` | `infra/add-monitoring` | Infrastructure changes |
| `ci/` | `ci/update-workflows` | CI/CD changes |

### Working on Your Changes

```bash
# 1. Create and switch to branch
git checkout -b feature/your-feature-name

# 2. Make changes
# Edit files in app/, terraform/, docs/, etc.

# 3. Test locally
npm run dev           # Test frontend
npm run type-check   # Check TypeScript
npm run build        # Production build
terraform plan       # Check infrastructure changes

# 4. Commit changes (see Commit Conventions)
git add -A
git commit -m "type: description"

# 5. Push to your fork
git push origin feature/your-feature-name
```

---

## Submitting Changes

### Before You Submit

✅ **Checklist:**

- [ ] Code follows project style (see [Coding Standards](#coding-standards))
- [ ] TypeScript compiles without errors (`npm run type-check`)
- [ ] Code builds successfully (`npm run build`)
- [ ] Commit message follows conventions (see [Commit Conventions](#commit-conventions))
- [ ] Documentation updated (if needed)
- [ ] Tests added/updated (if applicable)
- [ ] No unnecessary files committed (`.env`, `node_modules/`, `.terraform/`)
- [ ] Branch is up to date with upstream main

### Sync with Upstream

Before submitting, sync with the original repository:

```bash
# 1. Fetch latest from upstream
git fetch upstream

# 2. Rebase your branch
git rebase upstream/main

# 3. Resolve any conflicts
# If conflicts occur, resolve them manually in your editor

# 4. Force push to your fork
git push --force-with-lease origin feature/your-feature-name
```

### Submit Pull Request

1. **Go to GitHub**
   - Visit your fork: <https://github.com/YOUR_USERNAME/aether-drone>
   - Click "Compare & pull request" button

2. **Fill in PR Details**
   - **Title:** Short, descriptive title
   - **Description:** Use the template below

3. **PR Description Template**

```markdown
## Description
Brief explanation of what this PR does.

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that causes existing functionality to change)
- [ ] Documentation update

## Related Issue
Closes #[issue number]

## Changes Made
- Change 1
- Change 2
- Change 3

## Testing
Describe how you tested these changes:
1. Test 1
2. Test 2

## Screenshots (if applicable)
[Include before/after screenshots]

## Checklist
- [ ] Code follows style guidelines
- [ ] TypeScript compiles (`npm run type-check`)
- [ ] Build succeeds (`npm run build`)
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] No breaking changes (or documented)
```

4. **Click "Create pull request"**

---

## Pull Request Process

### Review Process

1. **Automated Checks**
   - GitHub Actions runs tests and linting
   - Must pass before review

2. **Code Review**
   - Project maintainers review your code
   - May request changes
   - Be responsive to feedback

3. **Address Feedback**

   ```bash
   # Make requested changes
   git add -A
   git commit -m "review: address feedback on PR"
   git push origin feature/your-feature-name
   ```

4. **Approval & Merge**
   - Maintainers approve
   - PR is merged to main
   - Your feature goes live!

### What to Expect

**Timeline:** 2-7 days typically

**Feedback:**

- ✅ Constructive and respectful
- May include suggestions for improvements
- Don't take personally - goal is best code quality

**If Rejected:**

- Maintainers explain why
- Feel free to discuss or revise
- Always open to re-submission

---

## Coding Standards

### TypeScript

**Use type hints everywhere:**

```typescript
// ✅ Good
const getUserLocation = (headers: Record<string, string>): LocationData => {
  const city: string = headers.get("cloudfront-viewer-city") || "Unknown";
  const count: number = parseInt(value);
  return { city };
};

// ❌ Bad
const getUserLocation = (headers) => {
  const city = headers.get("cloudfront-viewer-city") || "Unknown";
  return { city };
};
```

**Avoid `any` type:**

```typescript
// ✅ Good
interface UserData {
  name: string;
  age: number;
}
const user: UserData = getData();

// ❌ Bad
const user: any = getData();
```

---

### React/Next.js

**Use functional components with hooks:**

```typescript
// ✅ Good
export default function Dashboard(): React.ReactElement {
  const [location, setLocation] = useState<string>("Loading...");
  
  useEffect(() => {
    fetchLocation();
  }, []);

  return <div>{location}</div>;
}

// ❌ Bad
class Dashboard extends React.Component {
  // Old class-based component
}
```

**Proper prop typing:**

```typescript
// ✅ Good
interface ButtonProps {
  label: string;
  onClick: () => void;
  disabled?: boolean;
}

const Button: React.FC<ButtonProps> = ({ label, onClick, disabled }) => (
  <button onClick={onClick} disabled={disabled}>{label}</button>
);

// ❌ Bad
const Button = ({ label, onClick }) => (
  <button onClick={onClick}>{label}</button>
);
```

---

### Terraform

**Use consistent formatting:**

```hcl
# ✅ Good - Formatted and commented
resource "aws_lambda_function" "api_handler" {
  function_name = "${var.project_name}-api-handler"
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  
  # Enable X-Ray tracing for performance monitoring
  tracing_config {
    mode = "Active"
  }
}

# ❌ Bad - No comments, inconsistent formatting
resource "aws_lambda_function" "api_handler" {
  function_name = "${var.project_name}-api-handler"
  handler="handler.lambda_handler"
  runtime="python3.12"
}
```

**Use variables for magic numbers:**

```hcl
# ✅ Good
variable "lambda_timeout" {
  default = 30
  description = "Lambda execution timeout in seconds"
}

resource "aws_lambda_function" "api_handler" {
  timeout = var.lambda_timeout
}

# ❌ Bad - Magic number
resource "aws_lambda_function" "api_handler" {
  timeout = 30
}
```

---

### Python (Lambda)

**Use type hints:**

```python
# ✅ Good
from typing import Dict, Any

def get_visitor_location(event: Dict[str, Any]) -> Dict[str, Any]:
    headers: Dict[str, str] = event.get("headers", {})
    city: str = headers.get("cloudfront-viewer-city", "Unknown")
    return {"city": city}

# ❌ Bad
def get_visitor_location(event):
    headers = event.get("headers", {})
    city = headers.get("cloudfront-viewer-city", "Unknown")
    return {"city": city}
```

**Use meaningful variable names:**

```python
# ✅ Good
cloudfront_distribution_id = "E1A2B3C4D5E6F7G8"
waf_block_count = 42
api_response_time_ms = 145

# ❌ Bad
dist_id = "E1A2B3C4D5E6F7G8"
count = 42
time = 145
```

---

### CSS/Tailwind

**Use Tailwind utility classes:**

```jsx
// ✅ Good
<div className="flex items-center justify-between p-4 bg-gray-100 rounded-lg">
  <h1 className="text-2xl font-bold text-gray-900">Title</h1>
</div>

// ❌ Bad - Custom CSS when Tailwind has utilities
<style>
  .container { display: flex; padding: 1rem; }
</style>
<div className="container">
```

---

## Commit Conventions

### Commit Message Format

Follow conventional commits:

```
type(scope): subject

body

footer
```

### Type

```
feat:     A new feature
fix:      A bug fix
docs:     Documentation only changes
refactor: Code change that neither fixes a bug nor adds a feature
perf:     Code change that improves performance
test:     Adding missing tests or correcting existing tests
ci:       Changes to CI configuration files and scripts
chore:    Changes that don't modify src or test files
```

### Scope

Optional but recommended:

```
feat(api): add new endpoint
fix(lambda): handle missing headers
docs(readme): update installation steps
refactor(styles): consolidate Tailwind classes
```

### Subject

- Use imperative mood ("add" not "added")
- Don't capitalize first letter
- No period at the end
- Limit to 50 characters

### Body

Optional but recommended for non-trivial changes:

```
- Explain what and why, not how
- Wrap at 72 characters
- Separate from subject with blank line
```

### Examples

```
✅ GOOD:
feat(location): add case-insensitive header lookup
fix(waf): handle missing X-Amz-Cf-Id header
docs(deployment): update step-by-step guide
refactor(lambda): extract header parsing logic
perf(cloudfront): increase cache TTL for assets

❌ BAD:
added feature
fixed bug
Updated
Changed stuff
wip (work in progress)
```

### Commits to Avoid

```bash
# ❌ Bad commits
git commit -m "fix"
git commit -m "lol"
git commit -m "idk why this works"
git commit -m "temporary"

# ✅ Good commits
git commit -m "fix(api): handle null response from Lambda"
git commit -m "docs: clarify deployment steps"
git commit -m "test: add unit tests for location parsing"
```

---

## Testing

### Local Testing

Before submitting PR:

```bash
# 1. Type checking
npm run type-check
# ✅ Should pass without errors

# 2. Build
npm run build
# ✅ Should complete successfully

# 3. Development server
npm run dev
# ✅ Open http://localhost:3000 and verify changes

# 4. Test your changes
# - Click buttons
# - Navigate pages
# - Check console for errors (F12)
```

### Infrastructure Testing

For Terraform changes:

```bash
# 1. Validate syntax
cd terraform
terraform validate
# ✅ Should pass

# 2. Check for issues
terraform plan
# ✅ Review planned changes

# 3. If major changes:
# Create test infrastructure
terraform apply
# ✅ Verify changes work
terraform destroy
# ✅ Clean up test resources
```

### Adding Tests

If you're adding new functionality:

```bash
# Create test file
touch app/components/__tests__/NewComponent.test.tsx

# Example test
import { render, screen } from '@testing-library/react';
import NewComponent from '../NewComponent';

describe('NewComponent', () => {
  test('renders component', () => {
    render(<NewComponent />);
    expect(screen.getByText(/expected text/i)).toBeInTheDocument();
  });
});
```

Run tests:

```bash
npm run test
# Or with watch mode
npm run test:watch
```

---

## Documentation

### Update Docs for Changes

If your change affects:

**Frontend:**

- Update `README.md` if new feature
- Update API documentation if endpoint changes
- Add comments to complex code

**Infrastructure:**

- Update `terraform/README.md`
- Document new variables
- Update architecture docs if major change

**Deployment:**

- Update `docs/DEPLOYMENT.md` if process changes
- Update `docs/CI-CD.md` if workflows change

### Documentation Style

**Use clear language:**

```markdown
✅ Good:
The Lambda function receives CloudFront headers and extracts location data.

❌ Bad:
The function processes headers for geo stuff.
```

**Include examples:**

```markdown
✅ Good:
To deploy: git push origin main

❌ Bad:
Deploy the thing
```

**Add code blocks:**

````markdown
✅ Good:
```bash
npm run build
```

❌ Bad:
Run npm run build
````

---

## Areas for Contribution

### Need Ideas? Here Are Ways to Help

**Code:**

- 🛠️ Fix reported bugs
- ✨ Implement requested features
- ⚡ Optimize performance
- 🔐 Improve security
- ♿ Enhance accessibility

**Documentation:**

- 📝 Improve existing docs
- 📖 Add tutorials
- 🎯 Create quick-start guides
- 📄 Fix typos and clarity
- 🌍 Translate to other languages

**Infrastructure:**

- 🏗️ Improve Terraform configuration
- 📊 Add monitoring
- 💰 Reduce costs
- 🛡️ Enhance security
- ⚙️ Automate deployments

**Testing:**

- ✅ Add unit tests
- 🧪 Add integration tests
- 📈 Improve test coverage
- 🐛 Report edge cases
- 🔬 Stress testing

**Community:**

- 💬 Help other contributors
- 📢 Share the project
- 🗣️ Provide feedback
- 🤝 Mentor newcomers
- 📰 Write blog posts

---

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT).

---

## Recognition

All contributors are recognized in:

- **CONTRIBUTORS.md** - List of all contributors
- **GitHub** - As pull request author
- **Releases** - Mentioned in release notes

Thank you for contributing! 🙏

---

## Getting Help

### When to Ask

- **Development questions:** GitHub Discussions
- **Bug reports:** GitHub Issues with details
- **General questions:** Check existing issues first
- **PR feedback:** Respond in the PR thread

### Common Questions

**Q: How long until my PR is reviewed?**
A: Usually 2-7 days. Maintainers are volunteers with other commitments.

**Q: My PR was rejected. What now?**
A: Review feedback, discuss if needed, revise and resubmit.

**Q: How do I update my fork?**
A:

```bash
git fetch upstream
git rebase upstream/main
git push --force-with-lease origin main
```

**Q: Should I create an issue before a PR?**
A: For large changes, yes. For small fixes, PR is fine.

**Q: Can I work on multiple features?**
A: Yes, but keep PRs focused. One feature per PR is ideal.

---

## Quick Reference

### Most Common Workflows

**Fix a bug:**

```bash
git checkout -b fix/issue-name
# Edit files
git add -A
git commit -m "fix(component): description"
git push origin fix/issue-name
# Create PR on GitHub
```

**Add a feature:**

```bash
git checkout -b feature/feature-name
# Edit files
npm run type-check
npm run build
git add -A
git commit -m "feat(component): description"
git push origin feature/feature-name
# Create PR on GitHub
```

**Update documentation:**

```bash
git checkout -b docs/update-name
# Edit markdown files
git add docs/
git commit -m "docs(section): update description"
git push origin docs/update-name
# Create PR on GitHub
```

---

## Summary

* ✅ Fork and clone repository
* ✅ Create feature branch
* ✅ Make changes following code standards
* ✅ Test locally (type-check, build, dev server)
* ✅ Commit with conventional messages
* ✅ Sync with upstream
* ✅ Submit pull request with description
* ✅ Address review feedback
* ✅ Celebrate when merged! 🎉

**Questions?** Feel free to ask in issues or discussions!

**Ready to contribute?** Start with the [Development Setup](#development-setup) section above.

Thank you for making Aether Drone better! ✨
