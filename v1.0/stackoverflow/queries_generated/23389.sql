WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
CloseVoteCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseVotes
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 -- Close
    GROUP BY ph.PostId
),
ScoreWithCloseVotes AS (
    SELECT 
        p.PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(c.CloseVotes, 0) AS CloseVotes
    FROM RankedPosts p
    LEFT JOIN CloseVoteCounts c ON p.PostId = c.PostId
),
UserReport AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    sr.PostId, 
    sr.Title, 
    sr.ViewCount, 
    sr.Score,
    sr.CloseVotes, 
    ur.UserId, 
    ur.DisplayName, 
    ur.BadgeCount, 
    ur.UpVotes, 
    ur.DownVotes
FROM ScoreWithCloseVotes sr
JOIN UserReport ur ON sr.PostId = (
    SELECT p.Id
    FROM Posts p
    WHERE p.OwnerUserId = ur.UserId
    ORDER BY p.Score DESC LIMIT 1
)
WHERE sr.Rank <= 5
  AND sr.CloseVotes > 0
  AND ur.BadgeCount > 0
  AND ur.LastAccessDate IS NOT NULL
  AND ur.Reputation BETWEEN 100 AND 1000
ORDER BY sr.Score DESC, sr.ViewCount DESC;
This SQL query retrieves top-ranked posts from the last year that have been closed, along with their owners' detailed user information. It employs several advanced SQL constructs:

1. **Common Table Expressions (CTEs)** to break down the query logically into ranked posts, close vote counts, and user reports.
2. **Window Functions** to rank posts based on scores and view counts.
3. **Correlated Subqueries** for selecting the highest-scoring post related to a user based on the user's ID.
4. **OUTER Joins** to ensure all posts are retained even if there are no associated close votes.
5. **NULL Logic** (using `COALESCE`) to handle situations where no close votes exist.
6. **Complicated predicates** to filter records based on multiple conditions related to user reputations and activity levels. 

This combination of SQL elements results in a complex yet informative query useful for performance benchmarking and analysis.
