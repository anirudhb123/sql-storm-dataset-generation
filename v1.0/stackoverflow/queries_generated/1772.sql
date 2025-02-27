WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.Reputation
),
PostWithUserReputation AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.Score,
        ur.Reputation AS UserReputation,
        ur.BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        UserReputation ur ON u.Id = ur.UserId
)
SELECT 
    pw.UserReputation,
    pw.BadgeCount,
    COUNT(*) FILTER (WHERE pw.Score > 10) AS HighScoringPosts,
    ARRAY_AGG(pw.Title) AS PostTitles
FROM 
    PostWithUserReputation pw
GROUP BY 
    pw.UserReputation, pw.BadgeCount
HAVING 
    COUNT(*) > 5
ORDER BY 
    UserReputation DESC
LIMIT 10;

WITH ClosureReasons AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS CloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    p.Id AS PostId,
    p.Title,
    CASE WHEN cr.CloseDate IS NOT NULL THEN 'Closed' ELSE 'Open' END AS PostStatus,
    COALESCE(cr.CloseReason, 'N/A') AS CloseReason
FROM 
    Posts p
LEFT JOIN 
    ClosureReasons cr ON p.Id = cr.PostId
WHERE 
    p.ViewCount > 100
ORDER BY 
    p.CreationDate DESC;
