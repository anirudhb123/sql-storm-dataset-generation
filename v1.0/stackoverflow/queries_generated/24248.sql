WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM Posts p
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN c.CreationDate >= CURRENT_DATE - INTERVAL '1 month' THEN 1 ELSE 0 END) AS RecentComments
    FROM Users u
    LEFT JOIN Comments c ON u.Id = c.UserId
    GROUP BY u.Id
),

PostHistoryFilter AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY ph.PostId
),
ClosedPostCount AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseOccurrences
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) -- Post Closed, Post Reopened
    GROUP BY ph.PostId
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(pp.PostId, 0) AS PopularPostId,
    pp.Title AS PopularPostTitle,
    pp.ViewCount,
    pp.Score AS PostScore,
    phf.EditCount,
    COALESCE(cpc.CloseOccurrences, 0) AS ClosedOccurrences,
    au.CommentCount AS TotalComments,
    au.RecentComments AS CommentsInLastMonth
FROM RankedUsers u
LEFT JOIN PopularPosts pp ON u.UserId = pp.PostId
LEFT JOIN PostHistoryFilter phf ON pp.PostId = phf.PostId
LEFT JOIN ClosedPostCount cpc ON pp.PostId = cpc.PostId
LEFT JOIN ActiveUsers au ON u.Id = au.Id
WHERE 
    u.Reputation > 1000 
    AND NOT EXISTS (SELECT 1 FROM Votes v WHERE v.UserId = u.UserId AND v.VoteTypeId IN (3, 12)) -- Exclude users with downvotes or deleted posts
ORDER BY 
    u.Reputation DESC,
    pp.ViewCount DESC,
    phf.EditCount DESC
FETCH FIRST 100 ROWS ONLY;
