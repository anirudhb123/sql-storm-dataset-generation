WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3) AS NetVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY SUM(v.VoteTypeId = 2) DESC) AS RankByUpvotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.OwnerUserId
),
AcceptedAnswers AS (
    SELECT 
        p.Id AS PostId,
        p.AcceptedAnswerId,
        CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END AS HasAcceptedAnswer
    FROM Posts p
),
BadgesEarned AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM Badges b
    WHERE b.Date >= NOW() - INTERVAL '1 year'
    GROUP BY b.UserId
)
SELECT 
    u.DisplayName,
    ps.Title,
    ps.CommentCount,
    ps.NetVotes,
    COALESCE(b.BadgeCount, 0) AS RecentBadgeCount,
    COALESCE(b.HighestBadgeClass, 0) AS HighestBadgeClass,
    pa.HasAcceptedAnswer,
    CASE
        WHEN ps.RankByUpvotes <= 10 AND COALESCE(b.BadgeCount, 0) > 5 THEN 'High Engagement Contributor'
        WHEN ps.NetVotes > 100 THEN 'Popular Poster'
        ELSE 'Regular Contributor'
    END AS ContributorCategory
FROM PostStatistics ps
JOIN Users u ON ps.OwnerUserId = u.Id
LEFT JOIN BadgesEarned b ON u.Id = b.UserId
LEFT JOIN AcceptedAnswers pa ON ps.PostId = pa.PostId
WHERE ps.NetVotes IS NOT NULL
AND (ps.CommentCount > 0 OR pa.HasAcceptedAnswer = 1)
ORDER BY ps.NetVotes DESC, ps.CommentCount DESC, ps.Title;
This SQL query benchmarks the performance of various components in a Stack Overflow-like schema by analyzing posts, users, comments, votes, and badges across different conditions and aggregating the results. It employs Common Table Expressions (CTEs), window functions, outer joins, an intricate filtering criteria, and NULL logic to dynamically categorize users based on their engagement with posts.
