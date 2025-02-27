WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '30 days')
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
)
SELECT 
    u.UserId,
    u.DisplayName,
    ua.CommentCount,
    ua.PositivePostCount,
    ua.BadgeCount,
    rp.Title,
    rp.Score,
    rp.CreationDate 
FROM 
    UserActivity ua
JOIN 
    RankedPosts rp ON ua.PositivePostCount > 0
LEFT JOIN 
    Posts p ON p.OwnerUserId = ua.UserId
WHERE 
    (ua.BadgeCount > 0 OR ua.CommentCount > 5)
    AND rp.Rank <= 5
ORDER BY 
    ua.PositivePostCount DESC, 
    rp.Score DESC
LIMIT 10;
