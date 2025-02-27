WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),

UserPostAggregates AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalScore,
        AvgViewCount,
        RANK() OVER (ORDER BY TotalScore DESC) AS UserRank
    FROM 
        UserPostAggregates
)

SELECT 
    pu.PostId,
    pu.Title,
    pu.Score,
    pu.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(rh.Level, -1) AS HierarchyLevel,
    t.UserRank,
    CASE 
        WHEN t.UserRank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType
FROM 
    RecursivePostHierarchy pu
LEFT JOIN 
    Users u ON pu.OwnerUserId = u.Id
LEFT JOIN 
    TopUsers t ON u.Id = t.UserId
LEFT JOIN 
    RecursivePostHierarchy rh ON pu.ParentId = rh.PostId
WHERE 
    pu.CreationDate > NOW() - INTERVAL '1 year'
ORDER BY 
    pu.Score DESC,
    pu.CreationDate DESC;

This SQL query performs the following complex operations:
1. Uses a recursive CTE (`RecursivePostHierarchy`) to retrieve posts and their hierarchy based on `ParentId`.
2. Aggregates user post data in another CTE (`UserPostAggregates`) to calculate total posts, score, and average view counts.
3. Determines the ranking of top users by their total score in `TopUsers`.
4. Joins these derived tables to extract all relevant data about the posts, their owners, and their hierarchy levels.
5. Filters results for posts created in the last year and categorizes users based on their ranking, providing a dynamic contributor type for display.
6. Orders results by score and creation date for performance benchmarking purposes.
