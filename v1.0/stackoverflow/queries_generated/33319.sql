WITH RECURSIVE PostHierarchy AS (
    -- Recursive CTE to provide a hierarchy of all posts and their accepted answers
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        1 as Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.PostTypeId,
        p2.AcceptedAnswerId,
        p2.ParentId,
        ph.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        PostHierarchy ph ON p2.ParentId = ph.Id
    WHERE 
        p2.PostTypeId = 2  -- Only answers
),
PostStats AS (
    -- CTE to calculate various statistics for questions and their answers
    SELECT 
        ph.Id AS PostId,
        ph.Title,
        ph.Level,
        COUNT(CASE WHEN ph.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        PostHierarchy ph
    LEFT JOIN 
        Posts p ON ph.Id = p.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- Vote types for bounties
    GROUP BY 
        ph.Id, ph.Title, ph.Level
),
ClosePostStats AS (
    -- CTE to find the stats for closed posts
    SELECT 
        ph.Id AS PostId,
        ph.Title,
        COUNT(CASE WHEN ph.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedCount
    FROM 
        PostHierarchy ph
    LEFT JOIN 
        Posts p ON ph.Id = p.Id
    GROUP BY 
        ph.Id, ph.Title
),
UserStats AS (
    -- CTE to count badges and total votes by user
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)
-- Final query
SELECT 
    ps.PostId,
    ps.Title,
    ps.Level,
    ps.AnswerCount,
    cps.ClosedCount,
    us.TotalBadges,
    us.UpVotes,
    us.DownVotes,
    us.UserId
FROM 
    PostStats ps
JOIN 
    ClosePostStats cps ON ps.PostId = cps.PostId
JOIN 
    Users u ON ps.PostId IN (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)
JOIN 
    UserStats us ON u.Id = us.UserId
WHERE 
    ps.Level = 1 -- Only top-level questions
ORDER BY 
    ps.AnswerCount DESC, ps.TotalBounty DESC;
