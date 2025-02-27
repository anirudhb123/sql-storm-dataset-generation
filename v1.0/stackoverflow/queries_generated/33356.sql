WITH RecursivePostHierarchy AS (
    -- CTE to get all answers and their corresponding questions
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.OwnerUserId,
        p.PostTypeId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions 

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title AS PostTitle,
        a.OwnerUserId,
        a.PostTypeId,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy q ON a.ParentId = q.PostId
    WHERE 
        a.PostTypeId = 2  -- Answers
),
PostStats AS (
    -- CTE to calculate view and vote counts per post
    SELECT 
        p.Id,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(v.VoteTypeId), 0) AS TotalVotes,
        p.ViewCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title
),
UserBadgeCounts AS (
    -- CTE to count the number of badges for each user
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryDetails AS (
    -- CTE to get the latest edit information for each post
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LatestEditDate,
        MAX(ph.PostHistoryTypeId) AS LatestEditTypeId
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    ph.LatestEditDate,
    ph.LatestEditTypeId,
    ps.UpVotes,
    ps.DownVotes,
    ps.TotalVotes,
    ps.ViewCount,
    ub.BadgeCount,
    r.Level AS AnswerLevel
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostStats ps ON p.Id = ps.Id
LEFT JOIN 
    UserBadgeCounts ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistoryDetails ph ON p.Id = ph.PostId
LEFT JOIN 
    RecursivePostHierarchy r ON r.PostId = p.Id
WHERE 
    p.PostTypeId = 1  -- Filter for questions
    AND (ph.LatestEditTypeId IS NULL OR ph.LatestEditDate > NOW() - INTERVAL '1 month')
    AND (ps.ViewCount > 100 OR r.Level > 0)
ORDER BY 
    ps.TotalVotes DESC, ps.ViewCount DESC
LIMIT 50;
