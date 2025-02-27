WITH RecursivePostHierarchy AS (
    -- CTE to get all answers and their associated questions in a hierarchical structure
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.PostTypeId,
        a.ParentId,
        Level + 1
    FROM 
        Posts a
    INNER JOIN RecursivePostHierarchy q ON a.ParentId = q.PostId
    WHERE 
        a.PostTypeId = 2 -- Answers
),
BadgedUsers AS (
    -- CTE to get users with badges and their reputation
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(b.Id) > 0
),
PostStats AS (
    -- CTE to aggregate post statistics including vote counts
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
FinalPostStats AS (
    -- CTE to join post statistics with the post hierarchy and users
    SELECT 
        r.PostId,
        r.Title,
        r.Level,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        bu.DisplayName,
        bu.Reputation,
        ROW_NUMBER() OVER (PARTITION BY r.PostId ORDER BY r.Level) AS RowNum
    FROM 
        RecursivePostHierarchy r
    LEFT JOIN 
        PostStats ps ON r.PostId = ps.PostId
    LEFT JOIN 
        Users u ON r.PostId IN (u.Id) -- Assuming posts are also owned by users
    LEFT JOIN
        BadgedUsers bu ON u.Id = bu.UserId
)

-- Final selection of data
SELECT 
    fps.PostId,
    fps.Title,
    fps.Level,
    fps.UpVotes,
    fps.DownVotes,
    fps.CommentCount,
    fps.DisplayName AS BadgeOwner,
    fps.Reputation AS OwnerReputation,
    CASE 
        WHEN fps.Reputation > 1000 THEN 'Experienced'
        WHEN fps.Reputation IS NULL THEN 'Unknown Reputation'
        ELSE 'Novice' 
    END AS UserLevel
FROM 
    FinalPostStats fps
WHERE 
    fps.RowNum = 1 -- Only get the top level posts (questions)
ORDER BY 
    fps.UpVotes DESC, fps.CommentCount DESC
LIMIT 10; -- Limit to top 10 posts to benchmark performance
