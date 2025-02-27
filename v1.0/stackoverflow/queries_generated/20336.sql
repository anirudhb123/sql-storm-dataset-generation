WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TopClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CloseReopenCount,
        p.CreationDate
    FROM 
        Posts p
    JOIN 
        PostHistories ph ON p.Id = ph.PostId
    WHERE 
        ph.CloseReopenCount > 0
    ORDER BY 
        ph.CloseReopenCount DESC
    LIMIT 5
)

SELECT 
    tu.DisplayName,
    COUNT(DISTINCT rp.PostId) AS PostsWritten,
    SUM(rp.ViewCount) AS TotalViews,
    AVG(tu.TotalScore) AS AverageUserScore,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     JOIN Posts p ON t.ExcerptPostId = p.Id 
     WHERE p.OwnerUserId = tu.UserId) AS RelatedTags,
    (SELECT string_agg(CONCAT('PostId: ', p.Id, ' - Title: ', p.Title), ' | ')
     FROM TopClosedPosts p) AS ClosedPosts
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.PostId
WHERE 
    tu.AvgReputation > (SELECT AVG(Reputation) FROM Users) 
GROUP BY 
    tu.UserId, tu.DisplayName
HAVING 
    COUNT(DISTINCT rp.PostId) > 5
ORDER BY 
    TotalViews DESC;

-- This query provides an overview of user engagement by:
-- - Selecting top users based on their average reputation,
-- - Counting the number of posts written and summing their views,
-- - Aggregating related tags from tags table, 
-- - Joining post histories to focus on recently closed and reopened posts.
