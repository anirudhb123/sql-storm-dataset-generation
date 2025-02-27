WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        CAST(0 AS int) AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with questions
    UNION ALL
    SELECT 
        a.Id,
        a.Title,
        a.CreationDate,
        a.Score,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostCTE r ON r.PostId = a.ParentId
),
CombinedVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'UpMod') AS UpvoteCount,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'DownMod') AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id
),
PostBadgeInfo AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadgeCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadgeCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    cv.UpvoteCount,
    cv.DownvoteCount,
    COALESCE(pb.UserId, 0) AS UserId,
    COALESCE(pb.GoldBadgeCount, 0) AS GoldBadges,
    COALESCE(pb.SilverBadgeCount, 0) AS SilverBadges,
    COALESCE(pb.BronzeBadgeCount, 0) AS BronzeBadges,
    CASE 
        WHEN rp.Score > 10 THEN 'High Score'
        WHEN rp.Score BETWEEN 5 AND 10 THEN 'Moderate Score'
        ELSE 'Low Score' 
    END AS ScoreCategory
FROM 
    RecursivePostCTE rp
LEFT JOIN 
    CombinedVoteCounts cv ON rp.PostId = cv.PostId
LEFT JOIN 
    (SELECT UserId, GoldBadgeCount, SilverBadgeCount, BronzeBadgeCount
     FROM PostBadgeInfo
     WHERE UserId IS NOT NULL) pb ON pb.UserId = rp.PostId  -- Assuming a mapping logic
WHERE 
    EXISTS (SELECT 1 FROM Comments c WHERE c.PostId = rp.PostId HAVING COUNT(*) > 0)
ORDER BY 
    rp.CreationDate DESC,
    rp.Score DESC;
