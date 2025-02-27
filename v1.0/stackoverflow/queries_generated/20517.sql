WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) FILTER (WHERE c.UserId IS NOT NULL) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(NULLIF(AVG(v.BountyAmount) FILTER (WHERE v.VoteTypeId = 8), 0), (SELECT AVG(v2.BountyAmount) FROM Votes v2 WHERE v2.PostId = p.Id)) AS AvgBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.Score > 0 AND 
        (p.CreationDate >= NOW() - INTERVAL '1 YEAR' OR p.ViewCount > 100)
),
FilteredPosts AS (
    SELECT 
        rp.*
    FROM 
        RankedPosts rp
    WHERE 
        (Rank = 1 OR CommentCount > 5) AND 
        AvgBounty IS NOT NULL
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.CreationDate,
    fp.ViewCount,
    CASE 
        WHEN U.Reputation < 1000 THEN 'Novice'
        WHEN U.Reputation BETWEEN 1000 AND 5000 THEN 'Experienced'
        ELSE 'Expert'
    END AS UserTier,
    COALESCE(B.BadgeCount, 0) AS BadgeCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    Users U ON U.Id = fp.OwnerUserId
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) B ON B.UserId = U.Id
WHERE 
    (fp.ViewCount > 200 OR fp.Score >= 10)
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC
LIMIT 10
OFFSET 5;

