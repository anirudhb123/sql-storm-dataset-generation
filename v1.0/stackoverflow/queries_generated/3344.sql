WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(NULLIF(rp.CommentCount, 0), 0) AS CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    CASE 
        WHEN rp.Score >= 100 THEN 'High Score'
        WHEN rp.Score >= 50 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS Score_Category,
    CASE 
        WHEN rp.rn = 1 THEN 'Most Recent Post of User'
        ELSE 'Older Post'
    END AS Post_Status
FROM RankedPosts rp
WHERE rp.ViewCount > 50
  AND rp.rn <= 3
ORDER BY rp.Score DESC, rp.ViewCount DESC;

WITH UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)

SELECT 
    u.DisplayName,
    u.Reputation,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
WHERE u.Reputation > 1000
  AND (ub.GoldBadges IS NOT NULL OR ub.SilverBadges IS NOT NULL OR ub.BronzeBadges IS NOT NULL)
ORDER BY u.Reputation DESC;

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    SUM(v.BountyAmount) AS TotalBounty
FROM PostTypes pt
LEFT JOIN Posts p ON pt.Id = p.PostTypeId
LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)
GROUP BY pt.Name
HAVING COUNT(p.Id) > 10
ORDER BY TotalBounty DESC;

SELECT 
    DISTINCT ON (t.TagName) t.TagName, 
    p.Title,
    p.CreationDate
FROM Tags t
JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
WHERE p.CreationDate >= (SELECT MIN(CreationDate) FROM Posts WHERE Score > 0)
  AND p.IsModeratorOnly = FALSE
ORDER BY t.TagName, p.CreationDate DESC;
