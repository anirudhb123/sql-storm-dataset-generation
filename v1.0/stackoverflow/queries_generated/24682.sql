WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass,
        SUM(CASE WHEN b.TagBased = 1 THEN 1 ELSE 0 END) AS TagBasedBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(COALESCE(b.Class, 0)) > 2
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        COUNT(ph.PostId) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= (SELECT MAX(CreationDate) FROM PostHistory WHERE PostHistoryTypeId IN (10, 11)) - INTERVAL '6 months'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.UserId
)
SELECT 
    p.PostId,
    p.ViewCount,
    p.Score,
    u.DisplayName,
    u.Reputation,
    COALESCE(pi.HistoryCount, 0) AS EditHistoryCount,
    COALESCE(tu.TotalBadgeClass, 0) AS UserBadgeClass,
    CASE
        WHEN pi.HistoryCount IS NULL THEN 'No History'
        WHEN pi.HistoryCount > 5 THEN 'Heavily Edited'
        ELSE 'Few Edits'
    END AS EditStatus,
    STRING_AGG(b.Name, ', ') AS BadgeNames
FROM 
    RankedPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistoryInfo pi ON p.PostId = pi.PostId
LEFT JOIN 
    TopUsers tu ON u.Id = tu.UserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.rn = 1
GROUP BY 
    p.PostId, p.ViewCount, p.Score, u.DisplayName, u.Reputation, pi.HistoryCount, tu.TotalBadgeClass
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100;

-- Notes on the query:
-- 1. The query utilizes CTEs for structuring data.
-- 2. It incorporates window functions for ranking posts by score and view count.
-- 3. Aggregations are done on badges and edit history across joins.
-- 4. `CASE` is used to classify the editing status of posts.
-- 5. The use of `STRING_AGG()` on badges demonstrates string aggregation capabilities.
-- 6. The query is designed to return top posts based on usage patterns while correlating user achievements and post editing activity.
