WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    COALESCE(u.UserId, -1) AS UserId,
    COALESCE(u.Reputation, 0) AS UserReputation,
    COALESCE(u.TotalBounty, 0) AS TotalBounty,
    COALESCE(u.BadgeCount, 0) AS BadgeCount,
    COALESCE(u.CommentCount, 0) AS CommentCount
FROM 
    RecentPosts p
LEFT JOIN 
    Users u ON p.PostId = u.Id
WHERE 
    p.rn = 1
ORDER BY 
    p.CreationDate DESC
LIMIT 50
UNION ALL
SELECT 
    NULL AS PostId,
    'Total Posts' AS Title,
    NULL AS CreationDate,
    COUNT(*) AS Score,
    NULL AS ViewCount,
    NULL AS AnswerCount,
    NULL AS UserId,
    NULL AS UserReputation,
    NULL AS TotalBounty,
    NULL AS BadgeCount,
    NULL AS CommentCount
FROM 
    Posts
WHERE 
    CreationDate >= CURRENT_DATE - INTERVAL '30 days';
