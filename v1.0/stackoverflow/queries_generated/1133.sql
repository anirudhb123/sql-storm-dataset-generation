WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 month'
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.UpVotes,
    ua.DownVotes,
    ua.PostCount,
    ua.CommentCount,
    rp.PostId,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate
FROM 
    UserActivity ua
LEFT JOIN 
    RecentPosts rp ON ua.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE 
    ua.PostCount > 0 
    AND (ua.UpVotes - ua.DownVotes) > 0
ORDER BY 
    ua.UpVotes DESC, ua.CommentCount DESC
LIMIT 10;
