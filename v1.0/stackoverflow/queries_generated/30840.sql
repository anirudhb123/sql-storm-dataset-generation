WITH UserStatistics AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AvgBounty,
        MAX(v.CreationDate) AS LastVoteDate,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS MostRecentPost
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.ViewCount > 50
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        COUNT(*) AS CloseCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 -- Close votes
    GROUP BY ph.PostId, ph.CreationDate, ph.UserDisplayName
),
CombinedStatistics AS (
    SELECT 
        us.DisplayName,
        us.TotalPosts,
        us.TotalComments,
        us.TotalUpVotes,
        us.TotalDownVotes,
        pa.Title,
        pa.CommentCount,
        pa.AvgBounty,
        pa.LastVoteDate,
        cp.CloseCount
    FROM UserStatistics us
    JOIN PostAnalytics pa ON us.Id = pa.PostId
    LEFT JOIN ClosedPosts cp ON pa.PostId = cp.PostId
)
SELECT 
    cs.DisplayName,
    cs.TotalPosts,
    cs.TotalComments,
    cs.TotalUpVotes,
    cs.TotalDownVotes,
    cs.Title,
    cs.CommentCount,
    cs.AvgBounty,
    COALESCE(cs.LastVoteDate, 'No Votes') AS LastVoteDate,
    COALESCE(cs.CloseCount, 0) AS CloseCount
FROM CombinedStatistics cs
ORDER BY cs.ReputationRank, cs.TotalPosts DESC
LIMIT 100;
