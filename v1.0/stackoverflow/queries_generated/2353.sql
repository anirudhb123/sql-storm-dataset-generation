WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadge
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.Title,
    rp.ViewCount,
    rp.ViewRank,
    uwb.DisplayName,
    uwb.BadgeCount,
    uwb.HighestBadge,
    COALESCE(NULLIF(rp.UpVotes, rp.DownVotes), 0) AS VoteDifference,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus
FROM 
    RankedPosts rp
JOIN 
    UsersWithBadges uwb ON rp.OwnerUserId = uwb.UserId
WHERE 
    (rp.Score IS NOT NULL AND rp.Score > 0)
    OR (rp.ViewCount IS NOT NULL AND rp.ViewCount >= 100)
ORDER BY 
    rp.ViewCount DESC
LIMIT 50;
