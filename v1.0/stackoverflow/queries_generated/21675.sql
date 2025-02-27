WITH UserReputation AS (
    SELECT U.Id AS UserId,
           U.Reputation,
           RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
),
PopularPosts AS (
    SELECT P.Id AS PostId,
           P.Title,
           P.Score,
           P.CreationDate,
           P.OwnerUserId,
           COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
           COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.Score, P.CreationDate, P.OwnerUserId
    HAVING P.Score > 0
),
ClosedPosts AS (
    SELECT P.Id AS PostId,
           P.Title,
           PH.UserDisplayName,
           PH.CreationDate,
           PH.Comment AS CloseReason,
           CASE
               WHEN PH.Comment IS NULL THEN 'Unspecified'
               ELSE PH.Comment
           END AS FinalCloseReason
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE PH.PostHistoryTypeId = 10 
      AND P.CreationDate < NOW() - INTERVAL '3 months'
),
PostAnalysis AS (
    SELECT P.Id AS PostId,
           P.Title,
           P.ViewCount,
           COALESCE(U.Reputation, 0) AS UserReputation,
           COALESCE(UP.UserRank, 999) AS UserRank,
           PP.Upvotes,
           PP.Downvotes,
           CP.CloseReason,
           CP.FinalCloseReason
    FROM Posts P
    LEFT JOIN UserReputation U ON P.OwnerUserId = U.UserId
    LEFT JOIN PopularPosts PP ON P.Id = PP.PostId
    LEFT JOIN ClosedPosts CP ON P.Id = CP.PostId
)
SELECT PA.PostId,
       PA.Title,
       PA.ViewCount,
       PA.UserReputation,
       PA.UserRank,
       PA.Upvotes,
       PA.Downvotes,
       PA.CloseReason,
       PA.FinalCloseReason,
       CASE 
           WHEN PA.CloseReason IS NOT NULL AND PA.UserReputation < 100 THEN 'Low Reputation - Closed Post'
           WHEN PA.UserRank <= 10 THEN 'Top User Post'
           ELSE 'Regular Post'
       END AS PostClassification,
       STRING_AGG(T.TagName, ', ') AS Tags
FROM PostAnalysis PA
LEFT JOIN Tags T ON PA.PostId = T.ExcerptPostId
GROUP BY PA.PostId, PA.Title, PA.ViewCount, PA.UserReputation, PA.UserRank, 
         PA.Upvotes, PA.Downvotes, PA.CloseReason, PA.FinalCloseReason
ORDER BY PA.ViewCount DESC, PA.UserReputation DESC
LIMIT 50;
