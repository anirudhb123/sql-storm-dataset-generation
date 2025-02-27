WITH RankedVotes AS (
    SELECT 
        V.PostId,
        V.VoteTypeId,
        RANK() OVER (PARTITION BY V.PostId ORDER BY V.CreationDate DESC) AS VoteRank
    FROM Votes V
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    WHERE B.Class = 1 -- Only gold badges
    GROUP BY B.UserId
),
PostAge AS (
    SELECT 
        P.Id,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - P.CreationDate)) / 86400 AS DaysOld
    FROM Posts P
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        PA.DaysOld,
        COALESCE(PH.Comment, 'No Comments Yet') AS LastEditComment,
        MAX(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS HasUpvote,
        MAX(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS HasDownvote
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN PostAge PA ON P.Id = PA.Id
    LEFT JOIN Comments C ON P.Id = C.PostId AND C.CreationDate = (SELECT MAX(C2.CreationDate) FROM Comments C2 WHERE C2.PostId = P.Id)
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.CreationDate = (SELECT MAX(PH2.CreationDate) FROM PostHistory PH2 WHERE PH2.PostId = P.Id AND PH2.PostHistoryTypeId = 5) 
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, U.DisplayName, PA.DaysOld, PH.Comment
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(PT.PostId) AS PostCount
    FROM Tags T
    JOIN PostsTags PT ON T.Id = PT.TagId
    GROUP BY T.TagName
    HAVING COUNT(PT.PostId) > 5
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.OwnerDisplayName,
    PD.DaysOld,
    U.BadgeCount,
    U.BadgeNames,
    PD.LastEditComment,
    (CASE 
        WHEN PD.HasUpvote = 1 AND PD.HasDownvote = 1 THEN 'Both Up and Downvoted'
        WHEN PD.HasUpvote = 1 THEN 'Has Upvote Only'
        WHEN PD.HasDownvote = 1 THEN 'Has Downvote Only'
        ELSE 'No Votes'
     END) AS VoteStatus
FROM PostDetails PD
LEFT JOIN UserBadges U ON PD.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = U.UserId)
WHERE PD.DaysOld > 30
ORDER BY PD.DaysOld DESC
LIMIT 50;
This SQL query combines several advanced constructs, including Common Table Expressions (CTEs), correlated subqueries, outer joins, conditional case statements, and aggregate functions. The goal is to extract meaningful information about active posts that have not been modified in over 30 days, along with user reputation badges and vote statuses, showcasing data in a multi-dimensional format suitable for performance benchmarking.
