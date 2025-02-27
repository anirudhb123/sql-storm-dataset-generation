WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
        SUM(p.ViewCount) AS TotalViews,
        DENSE_RANK() OVER (ORDER BY SUM(p.ViewCount) DESC) AS ViewRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT UserId, 
               SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY UserId
    ) v ON u.Id = v.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(ph.ClosedDate, 'No Closure') AS ClosureStatus,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) AS CloseCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE (p.CreationDate >= NOW() - INTERVAL '1 year' OR p.Score > 5)
    GROUP BY p.Id, p.Title, p.Score, ph.ClosedDate
),
AggregatedData AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        pm.PostId,
        pm.Title,
        pm.Score,
        pm.ClosureStatus,
        pm.CommentCount,
        pm.CloseCount,
        RANK() OVER (PARTITION BY ua.UserId ORDER BY pm.Score DESC) AS UserPostRank,
        ROW_NUMBER() OVER (PARTITION BY pm.ClosureStatus ORDER BY pm.CommentCount DESC) AS ClosureRank
    FROM UserActivity ua
    JOIN PostMetrics pm ON ua.UserId = pm.PostId 
)
SELECT DISTINCT 
    ad.DisplayName,
    ad.Title,
    ad.ClosureStatus,
    ad.CommentCount,
    ad.CloseCount,
    (ad.Score - (ad.CloseCount * 5)) AS AdjustedScore,
    CASE 
        WHEN ad.UserPostRank = 1 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType
FROM AggregatedData ad
WHERE AdjustedScore > 0
ORDER BY AdjustedScore DESC, ad.CommentCount DESC
LIMIT 100;
