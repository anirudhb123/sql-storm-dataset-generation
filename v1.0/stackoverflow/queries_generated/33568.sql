WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        0 AS PostCount,
        0 AS CommentCount,
        0 AS VoteCount,
        0 AS BadgeCount
    FROM Users U
    WHERE U.Reputation > 1000
    
    UNION ALL

    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id) AS PostCount,
        (SELECT COUNT(*) FROM Comments C WHERE C.UserId = U.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.UserId = U.Id) AS VoteCount,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id) AS BadgeCount
    FROM Users U
    INNER JOIN UserActivity UA ON U.Id = UA.UserId
    WHERE UA.PostCount = 0 -- Prevent infinite recursion by limiting depth
    LIMIT 1000
),
RankedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM Posts P
    WHERE P.Score > 10
),
BadgeStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS TotalBadges,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.CreationDate,
    UA.LastAccessDate,
    UA.PostCount,
    UA.CommentCount,
    UA.VoteCount,
    BS.TotalBadges,
    BS.BadgeNames,
    RP.Title AS TopPostTitle,
    RP.Score AS TopPostScore
FROM UserActivity UA
LEFT JOIN BadgeStats BS ON UA.UserId = BS.UserId
LEFT JOIN RankedPosts RP ON UA.UserId = RP.OwnerUserId AND RP.PostRank = 1
WHERE UA.PostCount > 0
ORDER BY UA.Reputation DESC, UA.LastAccessDate DESC;

This query performs a complex analysis of user activity on a Stack Overflow-like platform. It does the following:

1. **Recursive CTE (`UserActivity`)**: This gets users with a reputation greater than 1000, capturing their basic details as well as counts of posts, comments, votes, and badges.

2. **Window Function (`RankedPosts`)**: This ranks posts for each user based on their score, focusing on those with a score greater than 10.

3. **Aggregate Function (`BadgeStats`)**: This aggregates badge data for each user to see how many badges they have and what those badges are.

4. **Final Selection**: The main SELECT combines the data from the previous CTEs, filtering for users with posts while also ordering the results by reputation and last access date for insight into the most active and valued users.

A variety of constructs from the schema are utilized, including joins, aggregates, subqueries, window functions, and CTEs.
