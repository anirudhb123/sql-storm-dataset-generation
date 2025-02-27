WITH RecursivePostCTE AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.PostTypeId,
        P.AcceptedAnswerId,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        CAST(0 AS INT) AS Depth
    FROM Posts P
    WHERE P.PostTypeId = 1  -- Start with Questions
    UNION ALL
    SELECT 
        A.Id AS PostId,
        A.OwnerUserId,
        A.Title,
        A.PostTypeId,
        A.AcceptedAnswerId,
        A.CreationDate,
        A.LastActivityDate,
        A.Score,
        Depth + 1
    FROM Posts A
    INNER JOIN RecursivePostCTE Q ON Q.PostId = A.ParentId
    WHERE A.PostTypeId = 2  -- Only Answers
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM Votes 
    GROUP BY PostId
),
UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
LatestPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        B.BadgeCount,
        COALESCE(V.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(V.DownVoteCount, 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN UserBadgeCounts B ON U.Id = B.UserId
    LEFT JOIN PostVoteCounts V ON P.Id = V.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
) 
-- Main Query to get combined data of posts, votes, and badge counts
SELECT 
    LP.PostId,
    LP.Title,
    LP.CreationDate,
    LP.Score,
    LP.OwnerDisplayName,
    LP.BadgeCount,
    LP.UpVoteCount,
    LP.DownVoteCount,
    RP.Depth AS AnswerDepth
FROM LatestPosts LP
LEFT JOIN RecursivePostCTE RP ON LP.PostId = RP.PostId
WHERE LP.RN = 1  -- Only the latest post per user
ORDER BY LP.CreationDate DESC 
LIMIT 100;

This SQL query consists of several advanced SQL constructs:

1. **Common Table Expressions (CTEs)**: Recursive CTE to gather posts and their corresponding answers, helping find the relationship in terms of threads or discussion depth.
2. **Aggregations**: Using aggregations to get upvote and downvote counts from the Votes table, and badge counts from the Badges table for users.
3. **WINDOW FUNCTION**: The window function `ROW_NUMBER()` retrieves the most recent post for each user along with counting their associated votes and badges.
4. **LEFT JOINs**: Various joins ensure that even posts with no votes or badges are included in the result set.
5. **NULL Logic**: The `COALESCE` function is used to replace NULL values with 0 for vote counts.
6. **Complicated filtering**: The main query filters for posts created in the last 30 days and limits results to the most recent 100 entries.

This query showcases extensive SQL functionalities which can be useful in performance benchmarking and stress testing of SQL query execution.
