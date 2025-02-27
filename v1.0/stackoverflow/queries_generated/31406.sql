WITH RECURSIVE PostHierarchy AS (
    SELECT 
        Id,
        Title,
        AcceptedAnswerId,
        ParentId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Selecting only Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.AcceptedAnswerId,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- Only BountyStart votes
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        ph.Id AS PostId,
        ph.Title,
        ph.Level,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(v.Score, 0)) AS TotalVotes
    FROM 
        PostHierarchy ph
    LEFT JOIN 
        Comments c ON ph.Id = c.PostId
    LEFT JOIN 
        Votes v ON ph.Id = v.PostId
    LEFT JOIN 
        Users u ON u.Id = ph.AcceptedAnswerId
    GROUP BY 
        ph.Id, ph.Title, ic.Level, u.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Level,
    ps.OwnerName,
    ps.CommentCount,
    ps.TotalVotes,
    COALESCE(ups.PostCount, 0) AS UserPostCount,
    COALESCE(ups.TotalScore, 0) AS UserTotalScore,
    COALESCE(ups.TotalBounty, 0) AS UserTotalBounty
FROM 
    PostStats ps
LEFT JOIN 
    UserPostStats ups ON ps.OwnerName = ups.DisplayName
WHERE 
    ps.TotalVotes > 0 OR ups.PostCount IS NULL -- Include posts with votes or users with no posts
ORDER BY 
    ps.Level, ps.TotalVotes DESC, ps.CommentCount DESC
LIMIT 100;


This elaborate SQL query retrieves hierarchical data from a question and answer format (posts) while linking it back to user statistics. It employs recursive Common Table Expressions (CTEs) for analyzing question relationships, aggregates user post statistics, and computes the total votes each post received. Finally, it filters on posts with votes or users without posts and sorts the results to highlight the most significant interactions, limited to the top 100 entries.
