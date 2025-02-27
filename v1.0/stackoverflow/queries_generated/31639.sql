WITH RecursivePostHierarchy AS (
    -- Get the post hierarchy for questions and their answers
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions

    UNION ALL

    SELECT 
        p2.Id AS PostId,
        p2.ParentId,
        p2.Title,
        Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy rph ON p2.ParentId = rph.PostId
)

-- Main query to fetch user details, their posts, and any badges they have earned
SELECT 
    u.Id AS UserId,
    u.DisplayName AS UserName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    COALESCE(SUM(vote_count), 0) AS TotalVotes,
    MAX(p.CreationDate) AS LastPostDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    CASE 
        WHEN COUNT(DISTINCT b.Id) > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1
                     WHEN VoteTypeId = 3 THEN -1
                     ELSE 0 END) AS vote_count
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
LEFT JOIN 
    (
        SELECT 
            p.Id,
            unnest(string_to_array(p.Tags, ',')) AS TagName
        FROM 
            Posts p
    ) t ON p.Id = t.Id
WHERE 
    u.Reputation > 1000  -- Filter users with more than 1000 reputation
GROUP BY 
    u.Id
ORDER BY 
    TotalVotes DESC, 
    LastPostDate DESC
LIMIT 10;

-- Get details of posts with the maximum number of comments
SELECT 
    p.Id,
    p.Title,
    p.ViewCount,
    p.CommentCount,
    p.CreationDate,
    COALESCE(ROUND(AVG(p2.Score), 2), 0) AS AvgScore
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Posts p2 ON p.AcceptedAnswerId = p2.Id
WHERE 
    p.CommentCount > 0
GROUP BY 
    p.Id
HAVING 
    COUNT(c.Id) = (
        SELECT 
            MAX(CommentCount) 
        FROM 
            Posts
    )
ORDER BY 
    p.CreationDate DESC;

-- Recursive query to show badge earnings over time
WITH BadgeEarnings AS (
    SELECT 
        b.UserId,
        b.Name,
        b.Date,
        ROW_NUMBER() OVER (PARTITION BY b.UserId ORDER BY b.Date) AS RowNum
    FROM 
        Badges b
)
SELECT 
    u.DisplayName,
    be.Name AS BadgeName,
    be.Date,
    DENSE_RANK() OVER (PARTITION BY u.Id ORDER BY be.Date) AS BadgesEarnedCount
FROM 
    Users u
JOIN 
    BadgeEarnings be ON u.Id = be.UserId
ORDER BY 
    u.DisplayName, 
    be.Date;
