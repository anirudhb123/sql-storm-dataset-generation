WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COALESCE(b.Name, 'No Badge') AS UserBadge,
        u.Reputation,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS TotalComments,
        CASE 
            WHEN p.LastEditDate IS NULL THEN 'Never Edited' 
            ELSE to_char(p.LastEditDate, 'YYYY-MM-DD HH24:MI:SS')
        END AS LastEdited
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1  -- Gold Badges
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.UserBadge,
    rp.Reputation,
    rp.TotalComments,
    rp.LastEdited
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.Reputation DESC;

-- Get the total post interactions over all posts that are closed 
SELECT 
    COUNT(p.Id) AS TotalClosedPosts,
    SUM(CASE WHEN h.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseVotes,
    SUM(CASE WHEN h.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenVotes
FROM 
    Posts p
JOIN 
    PostHistory h ON p.Id = h.PostId
WHERE 
    p.ClosedDate IS NOT NULL;

-- Union of posts with more than 10 votes and posts with no votes but have comments
SELECT 
    p.Id,
    p.Title,
    'Has Votes' AS PostStatus
FROM 
    Posts p
WHERE 
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id) > 10

UNION

SELECT 
    p.Id,
    p.Title,
    'No Votes but Comments' AS PostStatus
FROM 
    Posts p
WHERE 
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id) = 0
    AND (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) > 0;

-- Correlated subquery to find users with posts that have the most comments
SELECT 
    u.DisplayName,
    u.Reputation,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) AS PostCount,
    (SELECT SUM(c.CommentCount) FROM (SELECT COUNT(*) AS CommentCount FROM Comments c WHERE c.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id) GROUP BY c.PostId) AS c) AS TotalCommentsForUser
FROM 
    Users u
WHERE 
    u.Reputation > 100
ORDER BY 
    TotalCommentsForUser DESC;

-- Final peculiar case: List users with zero interactions
SELECT 
    u.DisplayName,
    u.Reputation,
    'No Posts and No Comments' AS UserStatus
FROM 
    Users u
WHERE 
    u.Id NOT IN (SELECT OwnerUserId FROM Posts)
    AND u.Id NOT IN (SELECT UserId FROM Comments);
