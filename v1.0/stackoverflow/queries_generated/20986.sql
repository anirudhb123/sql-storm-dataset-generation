WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CASE 
            WHEN Reputation >= 1000 THEN 'High'
            WHEN Reputation >= 500 THEN 'Medium'
            WHEN Reputation >= 100 THEN 'Low'
            ELSE 'Newbie' 
        END AS ReputationCategory
    FROM Users
),
PostInteractions AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COALESCE(V.VoteTypeId, 0) AS LastVoteType,
        COUNT(C.Id) AS CommentCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostsCount,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.CreationDate = (
        SELECT MAX(V2.CreationDate) 
        FROM Votes V2 
        WHERE V2.PostId = P.Id
    )
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id, P.OwnerUserId
),
AggregatedData AS (
    SELECT 
        UI.Id AS UserId,
        UI.ReputationCategory,
        PI.PostId,
        PI.LastVoteType,
        PI.CommentCount,
        PI.RelatedPostsCount,
        PI.CloseReopenCount,
        ROW_NUMBER() OVER (PARTITION BY UI.ReputationCategory ORDER BY PI.CommentCount DESC) AS Rank
    FROM UserReputation UI
    INNER JOIN PostInteractions PI ON UI.Id = PI.OwnerUserId
)
SELECT 
    AD.UserId,
    AD.ReputationCategory,
    AD.PostId,
    AD.LastVoteType,
    AD.CommentCount,
    AD.RelatedPostsCount,
    AD.CloseReopenCount,
    CASE 
        WHEN AD.CloseReopenCount > 5 THEN 'Frequent Close/Reopen'
        ELSE 'Rarely Closed/Reopened' 
    END AS CloseReopenBehavior,
    COALESCE(SUM(AD2.CommentCount) FILTER (WHERE AD2.CommentCount > 0), 0) AS CommentsAcrossReputation
FROM AggregatedData AD
LEFT JOIN AggregatedData AD2 ON AD2.UserId = AD.UserId 
WHERE AD.Rank <= 10
GROUP BY AD.UserId, AD.ReputationCategory, AD.PostId, AD.LastVoteType, AD.CommentCount, 
         AD.RelatedPostsCount, AD.CloseReopenCount
HAVING COUNT(DISTINCT AD.PostId) > 1
ORDER BY AD.ReputationCategory, AD.CommentCount DESC;
