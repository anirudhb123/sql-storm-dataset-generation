WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.ViewCount,
    r.Score,
    ua.DisplayName,
    ua.VoteCount,
    ua.UpVotes,
    ua.DownVotes,
    COALESCE(ua.UpVotes, 0) - COALESCE(ua.DownVotes, 0) AS NetVotes,
    (SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = r.PostId) AS CommentCount,
    (SELECT JSON_AGG(b.Name) FROM Badges b WHERE b.UserId = r.OwnerUserId) AS UserBadges
FROM 
    RankedPosts r
LEFT JOIN 
    UserActivity ua ON r.OwnerUserId = ua.UserId
WHERE 
    r.rn = 1
ORDER BY 
    r.ViewCount DESC
LIMIT 10
UNION ALL
SELECT 
    NULL AS PostId,
    NULL AS Title,
    NULL AS CreationDate,
    NULL AS ViewCount,
    NULL AS Score,
    'Aggregate Statistics' AS DisplayName,
    COUNT(u.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS NetVotes,
    NULL AS CommentCount,
    NULL AS UserBadges
FROM 
    Users u
LEFT JOIN 
    Votes v ON u.Id = v.UserId;
