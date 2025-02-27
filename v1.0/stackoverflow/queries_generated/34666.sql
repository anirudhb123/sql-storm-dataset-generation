WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Starting with questions
    UNION ALL
    SELECT 
        a.Id,
        a.Title,
        a.CreationDate,
        a.Score,
        a.ViewCount,
        a.OwnerUserId,
        Level + 1
    FROM Posts a
    INNER JOIN RecursivePostCTE q ON a.ParentId = q.PostId
)
, UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostsCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostHistoryEvents AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEdit,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseEvents,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenEvents
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate AS QuestionCreated,
    u.DisplayName AS UserDisplayName,
    um.Reputation,
    r.Level,
    ph.FirstEdit,
    ph.CloseEvents,
    ph.ReopenEvents,
    um.PostsCount,
    um.TotalViews,
    um.TotalScore,
    ARRAY_AGG(DISTINCT pp.RelatedPostId) AS RelatedPosts,
    COUNT(c.Id) AS TotalComments
FROM RecursivePostCTE r
JOIN Users u ON r.OwnerUserId = u.Id
JOIN UserMetrics um ON u.Id = um.UserId
LEFT JOIN PostHistoryEvents ph ON r.PostId = ph.PostId
LEFT JOIN Comments c ON r.PostId = c.PostId
LEFT JOIN PostLinks pp ON r.PostId = pp.PostId
WHERE u.Reputation > 100 
AND r.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY r.PostId, r.Title, r.CreationDate, u.DisplayName, um.Reputation, r.Level, ph.FirstEdit, ph.CloseEvents, ph.ReopenEvents, um.PostsCount, um.TotalViews, um.TotalScore
ORDER BY r.Score DESC, r.ViewCount DESC;
