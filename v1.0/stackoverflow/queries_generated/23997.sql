WITH UserReputationCTE AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName, 
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
), 
PostDetailsCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostCount,
        MAX(V.CreationDate) AS LastVoteDate
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.OwnerUserId IS NOT NULL -- Only includes posts from registered users
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount, P.AcceptedAnswerId
), 
PostHistoryCTE AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS UpdateCount
    FROM PostHistory PH
    GROUP BY PH.PostId, PH.PostHistoryTypeId
), 
FinalResultCTE AS (
    SELECT 
        U.UserId, 
        U.DisplayName,
        COALESCE(PD.PostId, 0) AS PostId,
        COALESCE(PD.Title, 'No Title') AS Title,
        PD.Score,
        PD.ViewCount,
        PD.HasAcceptedAnswer,
        PH.UpdateCount AS EditCount,
        CASE 
            WHEN PD.CommentCount > 0 THEN CONCAT(PD.CommentCount, ' Comments')
            ELSE 'No Comments' 
        END AS CommentStatus,
        CASE 
            WHEN PD.RelatedPostCount > 0 THEN 'Related Posts Exist' 
            ELSE 'No Related Posts' 
        END AS RelatedStatus,
        U.ReputationRank,
        COALESCE(PH.LastVoteDate, (CURRENT_TIMESTAMP - INTERVAL '30 days')) AS LastVote
    FROM UserReputationCTE U 
    LEFT JOIN PostDetailsCTE PD ON U.UserId = PD.OwnerUserId
    LEFT JOIN PostHistoryCTE PH ON PD.PostId = PH.PostId
    WHERE U.Reputation > 100 -- Filter for only reputable users
    ORDER BY U.Reputation DESC, PD.Score DESC
)
SELECT 
    UserId,
    DisplayName,
    PostId,
    Title,
    Score,
    ViewCount,
    HasAcceptedAnswer,
    EditCount,
    CommentStatus,
    RelatedStatus,
    ReputationRank,
    LastVote
FROM FinalResultCTE
WHERE 
    (LastVote > CURRENT_TIMESTAMP - INTERVAL '30 days' OR HasAcceptedAnswer = 1)
ORDER BY ReputationRank, Score DESC;
