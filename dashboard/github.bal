import ballerina/http;
import ballerina/log;
import ballerina/os;

const string GITHUB_API_URL = "https://api.github.com";

// Initialize GitHub client with authentication
public function initGitHubClient() returns GitHubClient|error {
    string token = os:getEnv("BALLERINA_BOT_TOKEN");
    if token == "" {
        return error("BALLERINA_BOT_TOKEN environment variable not set");
    }

    return check new (GITHUB_API_URL, {
        auth: {
            token: token
        }
    });
}

// Fetch repository information
public function getRepoInfo(GitHubClient github, string org, string repo) returns GitHubRepo|error {
    string path = string `/repos/${org}/${repo}`;
    GitHubRepo response = check github->get(path);
    return response;
}

// Fetch latest release
public function getLatestRelease(GitHubClient github, string org, string repo) returns string|error {
    string path = string `/repos/${org}/${repo}/releases/latest`;
    GitHubRelease|http:ClientError response = github->get(path);

    if response is http:ClientError {
        log:printWarn(string `No release found for ${org}/${repo}`);
        return "N/A";
    }

    return response.tag_name;
}

// Fetch open issues count (excluding pull requests)
public function getOpenIssuesCount(GitHubClient github, string org, string repo) returns int|error {
    string path = string `/repos/${org}/${repo}/issues?state=open`;
    json[]|error issues = github->get(path);

    if issues is error {
        log:printWarn(string `Failed to fetch issues for ${org}/${repo}: ${issues.message()}`);
        return 0;
    }

    // Filter out pull requests (issues API returns both issues and PRs)
    int count = 0;
    foreach json issue in issues {
        if issue is map<json> {
            // Check if this is a pull request by looking for 'pull_request' field
            if !issue.hasKey("pull_request") {
                count += 1;
            }
        }
    }

    return count;
}

// Fetch open pull requests count
public function getOpenPRsCount(GitHubClient github, string org, string repo) returns int|error {
    string path = string `/repos/${org}/${repo}/pulls?state=open`;
    json[]|error pulls = github->get(path);

    if pulls is error {
        log:printWarn(string `Failed to fetch pull requests for ${org}/${repo}: ${pulls.message()}`);
        return 0;
    }

    return pulls.length();
}

// Fetch issues count by label from a repository
public function getIssuesByLabel(GitHubClient github, string org, string repo, string label) returns int|error {
    string path = string `/repos/${org}/${repo}/issues?state=open&labels=${label}`;
    json[]|error issues = github->get(path);

    if issues is error {
        log:printWarn(string `Failed to fetch issues for ${org}/${repo} with label ${label}: ${issues.message()}`);
        return 0;
    }

    // Filter out pull requests (issues API returns both issues and PRs)
    int count = 0;
    foreach json issue in issues {
        if issue is map<json> {
            // Check if this is a pull request by looking for 'pull_request' field
            if !issue.hasKey("pull_request") {
                count += 1;
            }
        }
    }

    return count;
}

// Check if repository has GitHub Actions workflow
public function hasGitHubActions(GitHubClient github, string org, string repo) returns boolean {
    string path = string `/repos/${org}/${repo}/actions/workflows`;
    json|error response = github->get(path);

    if response is error {
        return false;
    }

    if response is map<json> {
        int|error workflowCount = response.total_count.ensureType();
        if workflowCount is int {
            return workflowCount > 0;
        }
    }

    return false;
}

// Fetch product information from GitHub
public function fetchProductInfo(GitHubClient github, Product product) returns ProductInfo|error {
    string githubOrg = product.'github\-org ?: product.org;
    string productRepo = product.'product\-repository ?: string `product-${product.name}`;
    string docsRepo = product.'documentation\-repository ?: string `docs-${product.name}`;
    string helmRepo = product.'helm\-repository ?: string `helm-${product.name}`;

    // Fetch product repository information
    GitHubRepo repoInfo = check getRepoInfo(github, githubOrg, productRepo);
    string latestRelease = check getLatestRelease(github, githubOrg, productRepo);
    int openIssues = check getOpenIssuesCount(github, githubOrg, productRepo);
    int openPRs = check getOpenPRsCount(github, githubOrg, productRepo);
    boolean hasBuild = hasGitHubActions(github, githubOrg, productRepo);

    // Fetch documentation repository information
    int openDocsIssues = 0;
    int openDocsPRs = 0;

    int|error docsIssues = getOpenIssuesCount(github, githubOrg, docsRepo);
    if docsIssues is int {
        openDocsIssues = docsIssues;
    } else {
        log:printWarn(string `Documentation repository not found for ${product.name}: ${githubOrg}/${docsRepo}`);
    }

    int|error docsPRs = getOpenPRsCount(github, githubOrg, docsRepo);
    if docsPRs is int {
        openDocsPRs = docsPRs;
    }

    return {
        name: product.name,
        org: product.org,
        githubOrg: githubOrg,
        productRepo: productRepo,
        docsRepo: docsRepo,
        helmRepo: helmRepo,
        defaultBranch: repoInfo.default_branch,
        openIssues: openIssues,
        openPRs: openPRs,
        openDocsIssues: openDocsIssues,
        openDocsPRs: openDocsPRs,
        latestRelease: latestRelease,
        hasBuild: hasBuild
    };
}

// Fetch module information from GitHub
public function fetchModuleInfo(GitHubClient github, Module module) returns ModuleInfo|error {
    string githubOrg = module.'github\-org ?: "ballerina-platform";
    string moduleRepo = module.'module\-repository ?: string `module-${module.org}-${module.name}`;
    string libraryLabel = module.'library\-label ?: string `module/${module.name}`;
    string biLabel = module.'bi\-label ?: string `eventintegration/${module.name}`;

    GitHubRepo repoInfo = check getRepoInfo(github, githubOrg, moduleRepo);
    string latestRelease = check getLatestRelease(github, githubOrg, moduleRepo);
    int openPRs = check getOpenPRsCount(github, githubOrg, moduleRepo);
    boolean hasBuild = hasGitHubActions(github, githubOrg, moduleRepo);

    // Fetch library issues (from ballerina-library repo with specific label)
    int openLibraryIssues = check getIssuesByLabel(github, "ballerina-platform", "ballerina-library", libraryLabel);

    // Fetch BI issues (from product-ballerina-integrator repo with specific label)
    int openBIIssues = check getIssuesByLabel(github, "wso2", "product-ballerina-integrator", biLabel);

    return {
        name: module.name,
        org: module.org,
        githubOrg: githubOrg,
        moduleRepo: moduleRepo,
        libraryLabel: libraryLabel,
        biLabel: biLabel,
        defaultBranch: repoInfo.default_branch,
        openLibraryIssues: openLibraryIssues,
        openBIIssues: openBIIssues,
        openPRs: openPRs,
        latestRelease: latestRelease,
        hasBuild: hasBuild,
        codeCoverage: () // TODO: Fetch from CodeCov API if needed
    };
}

// Fetch tool information from GitHub
public function fetchToolInfo(GitHubClient github, Tool tool) returns ToolInfo|error {
    string githubOrg = tool.'github\-org ?: "ballerina-platform";
    string toolRepo = tool.'tool\-repository ?: string `${tool.name}-tools`;

    GitHubRepo repoInfo = check getRepoInfo(github, githubOrg, toolRepo);
    string latestRelease = check getLatestRelease(github, githubOrg, toolRepo);
    int openIssues = check getOpenIssuesCount(github, githubOrg, toolRepo);
    int openPRs = check getOpenPRsCount(github, githubOrg, toolRepo);
    boolean hasBuild = hasGitHubActions(github, githubOrg, toolRepo);

    return {
        name: tool.name,
        org: tool.org,
        githubOrg: githubOrg,
        toolRepo: toolRepo,
        libraryLabel: tool.'library\-label,
        biLabel: tool.'bi\-label,
        defaultBranch: repoInfo.default_branch,
        openIssues: openIssues,
        openPRs: openPRs,
        latestRelease: latestRelease,
        hasBuild: hasBuild
    };
}
