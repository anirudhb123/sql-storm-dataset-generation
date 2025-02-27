WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        RANK() OVER (ORDER BY SUM(u.UpVotes) DESC) AS UserRank
    FROM 
        Users u
    INNER JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostScore AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.ViewCount,
        COALESCE(ph.Level, 0) AS HierarchyLevel,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        t.TagName
    FROM 
        Posts p
    LEFT JOIN 
        RecursivePostHierarchy ph ON p.Id = ph.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
            PostId, STRING_AGG(Tags.TagName, ', ') AS TagName
        FROM 
            Posts
        CROSS JOIN 
            Tags
        WHERE 
            Tags.Id = ANY(string_to_array(Tags, '><')::int[])
        GROUP BY 
            PostId) t ON p.Id = t.PostId
),
FinalScore AS (
    SELECT 
        ps.PostId,
        ps.Score + (ps.ViewCount / 10) + (CASE WHEN ps.Reputation IS NULL THEN 0 ELSE ps.Reputation END) AS ComputedScore,
        ps.OwnerDisplayName,
        ps.TagName
    FROM 
        PostScore ps
)
SELECT 
    fs.PostId,
    fs.ComputedScore,
    fs.OwnerDisplayName,
    fs.TagName,
    tu.UserRank
FROM 
    FinalScore fs
LEFT JOIN 
    TopUsers tu ON fs.OwnerDisplayName = tu.DisplayName
WHERE 
    fs.ComputedScore >= 10
ORDER BY 
    fs.ComputedScore DESC, 
    tu.UserRank
LIMIT 50;
