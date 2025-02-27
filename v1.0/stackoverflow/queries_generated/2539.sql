WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    COALESCE(ub.BadgeNames, 'No Badges') AS Badges,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.UpVotes - rp.DownVotes DESC, 
    rp.CommentCount DESC, 
    rp.CreationDate DESC;
