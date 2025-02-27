WITH RecursiveCTE AS (
    SELECT Id, Title, OwnerUserId, AcceptedAnswerId, CreationDate, Score,
           ROW_NUMBER() OVER (PARTITION BY OwnerUserId ORDER BY CreationDate DESC) AS UserPostRank
    FROM Posts
    WHERE PostTypeId = 1  -- Only Questions
),
UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount, 
           STRING_AGG(Name, ', ') AS BadgeNames
    FROM Badges
    GROUP BY UserId
),
PostStatistics AS (
    SELECT P.Id, P.Title, U.DisplayName, P.CreationDate, 
           (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
           (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVotes,
           (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVotes,
           COALESCE(B.BadgeCount, 0) AS UserBadgeCount,
           COALESCE(B.BadgeNames, 'No Badges') AS UserBadges,
           CASE 
               WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 
               ELSE 0 
           END AS HasAcceptedAnswer
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN UserBadges B ON U.Id = B.UserId
    WHERE P.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT Id, Title, DisplayName, CreationDate, CommentCount, 
           UpVotes, DownVotes, UserBadgeCount, UserBadges,
           HasAcceptedAnswer,
           ROW_NUMBER() OVER (ORDER BY Score DESC) AS OverallRank
    FROM PostStatistics
    WHERE CommentCount > 0
)
SELECT 
    FP.Title,
    FP.DisplayName AS Owner,
    FP.CommentCount,
    FP.UpVotes,
    FP.DownVotes,
    FP.UserBadgeCount,
    FP.UserBadges,
    CASE WHEN HasAcceptedAnswer = 1 THEN 'Yes' ELSE 'No' END AS IsAccepted,
    RCTE.UserPostRank AS UserPostRank
FROM FilteredPosts FP
JOIN RecursiveCTE RCTE ON FP.Id = RCTE.Id
WHERE FP.OverallRank <= 10
ORDER BY FP.Score DESC, FP.CreationDate DESC;

This query performs an elaborate analysis of posts created within the last year, specifically focusing on questions. It leverages multiple constructs such as recursive CTEs, subqueries for comments and votes, LEFT JOINs to include badge information, window functions for ranking posts, and conditional expressions to handle NULLs and derive new columns. The final output provides insights into the top ten questions that received comments, along with metrics on user engagement and accolades.
