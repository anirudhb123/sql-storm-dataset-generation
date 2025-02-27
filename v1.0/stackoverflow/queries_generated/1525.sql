WITH UserBadgeCounts AS (
    SELECT 
        UserId, 
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostWithDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        OwnerDisplayName,
        CommentCount,
        PostRank
    FROM PostWithDetails
    WHERE PostRank = 1
)
SELECT 
    tb.OwnerDisplayName,
    COUNT(*) AS TopPostCount,
    SUM(COALESCE(ubc.GoldBadges, 0)) AS TotalGoldBadges,
    SUM(COALESCE(ubc.SilverBadges, 0)) AS TotalSilverBadges,
    SUM(COALESCE(ubc.BronzeBadges, 0)) AS TotalBronzeBadges
FROM TopPosts tb
LEFT JOIN UserBadgeCounts ubc ON tb.OwnerUserId = ubc.UserId
GROUP BY tb.OwnerDisplayName
HAVING COUNT(*) > 5
ORDER BY TopPostCount DESC
LIMIT 10;

WITH RECURSIVE ParentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ParentId
    FROM Posts p 
    WHERE p.ParentId IS NULL
    
    UNION ALL

    SELECT 
        p.Id AS PostId, 
        pp.Title, 
        p.ParentId
    FROM Posts p
    JOIN ParentPosts pp ON p.ParentId = pp.PostId
)
SELECT 
    pp.Title AS ChildPostTitle,
    COUNT(DISTINCT ph.PostId) AS RelatedPostCount
FROM ParentPosts pp
LEFT JOIN PostLinks pl ON pp.PostId = pl.PostId
LEFT JOIN Posts ph ON pl.RelatedPostId = ph.Id
GROUP BY pp.Title
ORDER BY RelatedPostCount DESC
LIMIT 20;
