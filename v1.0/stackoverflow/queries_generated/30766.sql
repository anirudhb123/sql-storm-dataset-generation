WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId, 
        ParentId, 
        Title, 
        0 AS Level 
    FROM 
        Posts 
    WHERE 
        ParentId IS NULL  -- Starting from root posts

    UNION ALL

    SELECT 
        p.Id, 
        p.ParentId, 
        p.Title, 
        r.Level + 1 
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostScoreSummary AS (
    SELECT
        p.Id,
        p.Title,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart votes
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'  -- Posts created in the last year
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(ps.Score) AS TotalScore,
        COUNT(DISTINCT ps.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts ps ON u.Id = ps.OwnerUserId
    WHERE 
        ps.CreationDate > NOW() - INTERVAL '1 year'  -- Users with posts created in the last year
    GROUP BY 
        u.Id
    HAVING 
        SUM(ps.Score) > 10  -- Users with total score > 10
),
FinalResults AS (
    SELECT 
        r.PostId,
        r.Title,
        ps.CommentCount,
        ps.TotalBounty,
        u.DisplayName AS TopUser,
        u.TotalScore
    FROM 
        RecursivePostHierarchy r
    LEFT JOIN 
        PostScoreSummary ps ON r.PostId = ps.Id
    LEFT JOIN 
        TopUsers u ON ps.ScoreRank = 1 -- Join to get the top user per post
)
SELECT 
    f.PostId,
    f.Title,
    COALESCE(f.CommentCount, 0) AS TotalComments,
    COALESCE(f.TotalBounty, 0) AS TotalBounty,
    f.TopUser,
    f.TotalScore
FROM 
    FinalResults f
LEFT JOIN 
    Tags t ON POSITION(t.TagName IN f.Title) > 0  -- Example predicate for tag matching
WHERE 
    t.TagName IS NOT NULL OR f.CommentCount > 0  -- Filtering condition
ORDER BY 
    f.TotalBounty DESC, 
    f.CommentCount DESC;  -- Ordering for performance benchmarking
