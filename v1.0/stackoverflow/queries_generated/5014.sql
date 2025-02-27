WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.Tags,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.Tags
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.Tags,
        rp.UpVotes,
        rp.DownVotes,
        ub.BadgeCount
    FROM
        RankedPosts rp
    JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.rn = 1
    ORDER BY 
        rp.Score DESC, rp.ViewCount DESC
    LIMIT 10
)
SELECT 
    p.PostId,
    p.Title,
    p.ViewCount,
    p.Score,
    p.Tags,
    p.UpVotes,
    p.DownVotes,
    p.BadgeCount
FROM 
    TopPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    u.Reputation > 1000
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
