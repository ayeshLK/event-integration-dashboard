import ballerina/http;

// Configuration types matching packages.json structure

public type Product record {|
    string name;
    string org;
    string github\-org?;
    string product\-repository?;
    string documentation\-repository?;
    string helm\-repository?;
|};

public type Module record {|
    string name;
    string org;
    string github\-org?;
    string 'module\-repository?;
    string library\-label?;
    string bi\-label?;
|};

public type Tool record {|
    string name;
    string org;
    string github\-org?;
    string tool\-repository?;
    string library\-label;
    string bi\-label;
|};

public type PackageConfig record {|
    Product[] products;
    Module[] modules;
    Tool[] tools;
|};

// Dashboard data types

public type ProductInfo record {
    string name;
    string org;
    string githubOrg;
    string productRepo;
    string docsRepo;
    string helmRepo;
    string defaultBranch;
    int openIssues;
    int openPRs;
    int openDocsIssues;
    int openDocsPRs;
    string latestRelease;
    boolean hasBuild;
};

public type ModuleInfo record {
    string name;
    string org;
    string githubOrg;
    string moduleRepo;
    string libraryLabel;
    string biLabel;
    string defaultBranch;
    int openLibraryIssues;
    int openBIIssues;
    int openPRs;
    string latestRelease;
    boolean hasBuild;
    string? codeCoverage;
};

public type ToolInfo record {
    string name;
    string org;
    string githubOrg;
    string toolRepo;
    string libraryLabel;
    string biLabel;
    string defaultBranch;
    int openIssues;
    int openPRs;
    string latestRelease;
    boolean hasBuild;
};

// GitHub API response types

public type GitHubRepo record {
    string name;
    string default_branch;
    int open_issues_count;
};

public type GitHubRelease record {
    string tag_name;
    string name;
};

public type GitHubClient http:Client;
