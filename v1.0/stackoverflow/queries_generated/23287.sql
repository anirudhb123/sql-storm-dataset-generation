WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RN,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
),
UserReputation AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        MAX(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadge,
        MAX(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadge,
        MAX(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadge
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
    u.Reputation,
    u.GoldBadge,
    u.SilverBadge,
    u.BronzeBadge,
    phs.CloseCount,
    phs.DeleteCount,
    CASE 
        WHEN p.Score > 0 THEN 'High Score'
        WHEN p.Score < 0 THEN 'Low Score'
        ELSE 'Neutral Score'
    END AS ScoreClassification,
    CASE 
        WHEN (p.ViewCount > 1000 AND phs.CloseCount > 5) THEN 'Highly Controversial'
        WHEN (p.ViewCount <= (SELECT AVG(ViewCount) FROM Posts) AND phs.CloseCount = 0) THEN 'Unpopular'
        ELSE 'Typical'
    END AS PopularityClassification
FROM 
    RankedPosts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistoryStats phs ON p.PostId = phs.PostId
WHERE 
    p.RN = 1
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

-- Additional analysis on User’s post interaction
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE 
            WHEN ph.PostId IS NOT NULL THEN 1 
            ELSE 0 
        END) AS EditedPosts,
    AVG(p.Score) AS AveragePostScore,
    STRING_AGG(t.TagName, ', ') AS AssociatedTags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) -- Edited title, body, tags
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, ',') AS t
GROUP BY 
    u.Id
HAVING 
    COUNT(p.Id) > 5
ORDER BY 
    TotalPosts DESC;
