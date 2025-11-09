import ballerina/io;

// URL encode a string for use in URLs
function urlEncode(string input) returns string {
    // Replace common characters that need encoding
    string encoded = input;
    encoded = re `/`.replaceAll(encoded, "%2F");
    encoded = re ` `.replaceAll(encoded, "%20");
    encoded = re `:`.replaceAll(encoded, "%3A");
    return encoded;
}

// Generate combined dashboard with all three sections
public function generateDashboard(ProductInfo[] products, ModuleInfo[] modules, ToolInfo[] tools) returns string {
    string dashboard = "<!-- This section is auto-generated. Do not edit manually. -->" + "\n\n";

    // Add products section
    dashboard += generateProductsSection(products);
    dashboard += "\n---\n\n";

    // Add modules section
    dashboard += generateModulesSection(modules);
    dashboard += "\n---\n\n";

    // Add tools section
    dashboard += generateToolsSection(tools);

    dashboard += "\n---\n\n" + string `*Last updated: ${getCurrentTimestamp()}*`;

    return dashboard;
}

// Generate products section for dashboard
function generateProductsSection(ProductInfo[] products) returns string {
    string dashboard = "## Products" + "\n\n";
    dashboard += "| Organization | Product Name | Latest Release | Open Product Issues | Open Product PRs | Open Documentation Issues | Open Documentation PRs | Build Status |" + "\n";
    dashboard += "|--------------|--------------|----------------|---------------------|------------------|---------------------------|------------------------|--------------|" + "\n";

    foreach ProductInfo product in products {
        string productLink = string `[${product.name}](https://github.com/${product.githubOrg}/${product.productRepo})`;
        string buildBadge = product.hasBuild ?
            string `[![Build](https://github.com/${product.githubOrg}/${product.productRepo}/workflows/Build/badge.svg)](https://github.com/${product.githubOrg}/${product.productRepo}/actions)` :
            "N/A";

        string productIssuesLink = string `[${product.openIssues}](https://github.com/${product.githubOrg}/${product.productRepo}/issues)`;
        string productPRsLink = string `[${product.openPRs}](https://github.com/${product.githubOrg}/${product.productRepo}/pulls)`;
        string docsIssuesLink = string `[${product.openDocsIssues}](https://github.com/${product.githubOrg}/${product.docsRepo}/issues)`;
        string docsPRsLink = string `[${product.openDocsPRs}](https://github.com/${product.githubOrg}/${product.docsRepo}/pulls)`;

        dashboard += string `| ${product.org} | ${productLink} | ${product.latestRelease} | ${productIssuesLink} | ${productPRsLink} | ${docsIssuesLink} | ${docsPRsLink} | ${buildBadge} |` + "\n";
    }

    return dashboard;
}

// Generate modules section for dashboard
function generateModulesSection(ModuleInfo[] modules) returns string {
    string dashboard = "## Modules" + "\n\n";
    dashboard += "| Module Name | Latest Release | Open Library Issues | Open BI Issues | Open Module PRs | Build Status | Code Coverage |" + "\n";
    dashboard += "|-------------|----------------|---------------------|----------------|-----------------|--------------|---------------|" + "\n";

    foreach ModuleInfo module in modules {
        string moduleLink = string `[${module.name}](https://github.com/${module.githubOrg}/${module.moduleRepo})`;
        string buildBadge = module.hasBuild ?
            string `[![Build](https://github.com/${module.githubOrg}/${module.moduleRepo}/workflows/Build/badge.svg)](https://github.com/${module.githubOrg}/${module.moduleRepo}/actions)` :
            "N/A";
        string coverageBadge = string `[![codecov](https://codecov.io/gh/${module.githubOrg}/${module.moduleRepo}/branch/${module.defaultBranch}/graph/badge.svg)](https://codecov.io/gh/${module.githubOrg}/${module.moduleRepo})`;

        string encodedLibraryLabel = urlEncode(module.libraryLabel);
        string encodedBiLabel = urlEncode(module.biLabel);
        string libraryIssuesLink = string `[${module.openLibraryIssues}](https://github.com/ballerina-platform/ballerina-library/issues?q=is:open+label:${encodedLibraryLabel})`;
        string biIssuesLink = string `[${module.openBIIssues}](https://github.com/wso2/product-ballerina-integrator/issues?q=is:open+label:${encodedBiLabel})`;
        string prsLink = string `[${module.openPRs}](https://github.com/${module.githubOrg}/${module.moduleRepo}/pulls)`;

        dashboard += string `| ${moduleLink} | ${module.latestRelease} | ${libraryIssuesLink} | ${biIssuesLink} | ${prsLink} | ${buildBadge} | ${coverageBadge} |` + "\n";
    }

    return dashboard;
}

// Generate tools section for dashboard
function generateToolsSection(ToolInfo[] tools) returns string {
    string dashboard = "## Tools" + "\n\n";
    dashboard += "| Tool | Organization | Latest Release | Open Issues | Open PRs | Build Status |" + "\n";
    dashboard += "|------|--------------|----------------|-------------|----------|-------------|" + "\n";

    foreach ToolInfo tool in tools {
        string toolLink = string `[${tool.name}](https://github.com/${tool.githubOrg}/${tool.toolRepo})`;
        string buildBadge = tool.hasBuild ?
            string `[![Build](https://github.com/${tool.githubOrg}/${tool.toolRepo}/workflows/Build/badge.svg)](https://github.com/${tool.githubOrg}/${tool.toolRepo}/actions)` :
            "N/A";

        string issuesLink = string `[${tool.openIssues}](https://github.com/${tool.githubOrg}/${tool.toolRepo}/issues)`;
        string prsLink = string `[${tool.openPRs}](https://github.com/${tool.githubOrg}/${tool.toolRepo}/pulls)`;

        dashboard += string `| ${toolLink} | ${tool.org} | ${tool.latestRelease} | ${issuesLink} | ${prsLink} | ${buildBadge} |` + "\n";
    }

    dashboard += "\n" + "### Issue Labels" + "\n\n";
    dashboard += "| Tool | Library Label | BI Label |" + "\n";
    dashboard += "|------|---------------|----------|" + "\n";

    foreach ToolInfo tool in tools {
        string encodedLibraryLabel = urlEncode(tool.libraryLabel);
        string encodedBiLabel = urlEncode(tool.biLabel);
        string libraryLink = string `[${tool.libraryLabel}](https://github.com/ballerina-platform/ballerina-library/issues?q=is:open+label:${encodedLibraryLabel})`;
        string biLink = string `[${tool.biLabel}](https://github.com/wso2/product-ballerina-integrator/issues?q=is:open+label:${encodedBiLabel})`;

        dashboard += string `| ${tool.name} | ${libraryLink} | ${biLink} |` + "\n";
    }

    return dashboard;
}

// Get current timestamp in readable format
function getCurrentTimestamp() returns string {
    // This is a simplified version - in real implementation you'd use time library
    return "2025-11-07"; // Placeholder
}

// Update dashboard section in README.md
public function updateDashboardInReadme(string dashboardContent, string filename) returns error? {
    // Read existing README
    string readmeContent = check io:fileReadString(filename);

    // Find the dashboard section markers
    string startMarker = "<!-- DASHBOARD_START -->";
    string endMarker = "<!-- DASHBOARD_END -->";

    int? startIndex = readmeContent.indexOf(startMarker);
    int? endIndex = readmeContent.indexOf(endMarker);

    if startIndex == () || endIndex == () {
        return error("Dashboard markers not found in README.md. Please ensure <!-- DASHBOARD_START --> and <!-- DASHBOARD_END --> markers exist.");
    }

    // Calculate position after start marker
    int contentStart = startIndex + startMarker.length();

    // Extract parts of README
    string beforeDashboard = readmeContent.substring(0, contentStart);
    string afterDashboard = readmeContent.substring(endIndex);

    // Construct new README with updated dashboard
    string newReadme = beforeDashboard + "\n" + dashboardContent + "\n" + afterDashboard;

    // Write back to file
    check io:fileWriteString(filename, newReadme);
    io:println(string `Dashboard section updated in ${filename}`);
}
