WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate >= NOW() - INTERVAL '2 years'
    GROUP BY 
        p.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN ub.BadgeCount IS NULL THEN 'No Gold Badge' 
        ELSE 'Gold Badge Holder' 
    END AS BadgeStatus,
    (SELECT COUNT(*) FROM Posts p2 WHERE p2.OwnerUserId = rp.OwnerPostRank) AS TotalPostsByOwner
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.PostId = ub.UserId
WHERE 
    rp.OwnerPostRank <= 3
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;
