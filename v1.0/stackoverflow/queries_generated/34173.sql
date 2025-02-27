WITH RecursiveTags AS (
    SELECT T.Id, T.TagName, T.Count, 0 AS Level
    FROM Tags T
    WHERE T.Count > 1000  -- Starting with popular tags
    
    UNION ALL
    
    SELECT T.Id, T.TagName, T.Count, RT.Level + 1
    FROM Tags T
    INNER JOIN PostLinks PL ON T.Id = PL.RelatedPostId
    INNER JOIN Posts P ON PL.PostId = P.Id
    INNER JOIN RecursiveTags RT ON P.Tags LIKE '%' || RT.TagName || '%'  
    WHERE RT.Level < 3  -- Limiting recursion depth to 3
),
RecentPosts AS (
    SELECT P.Id AS PostId, P.Title, P.CreationDate, P.Score, P.Tags, P.OwnerUserId, P.ViewCount,
           ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN
    FROM Posts P
    WHERE P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
),
PostVoteCounts AS (
    SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
           SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Votes
    GROUP BY PostId
),
PostHistorySummary AS (
    SELECT PH.PostId, COUNT(PH.Id) AS EditCount,
           MAX(PH.CreationDate) AS LastEditDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5)  -- Edit Title and Edit Body
    GROUP BY PH.PostId
),
FinalResults AS (
    SELECT RP.PostId, RP.Title, RP.CreationDate, RP.Score, 
           COALESCE(PUC.Upvotes, 0) AS Upvotes, COALESCE(PUC.Downvotes, 0) AS Downvotes,
           PHS.EditCount, PHS.LastEditDate, 
           String_agg(RT.TagName, ', ') AS RelatedTags
    FROM RecentPosts RP
    LEFT JOIN PostVoteCounts PUC ON RP.PostId = PUC.PostId
    LEFT JOIN PostHistorySummary PHS ON RP.PostId = PHS.PostId
    LEFT JOIN RecursiveTags RT ON RP.Tags LIKE '%' || RT.TagName || '%'
    WHERE RP.RN = 1  -- Only the most recent post per user
    GROUP BY RP.PostId, RP.Title, RP.CreationDate, RP.Score, PUC.Upvotes, PUC.Downvotes, PHS.EditCount, PHS.LastEditDate
)
SELECT *, 
       CASE 
           WHEN Upvotes > Downvotes THEN 'Net Positive'
           WHEN Downvotes > Upvotes THEN 'Net Negative'
           ELSE 'Neutral'
       END AS VoteStatus
FROM FinalResults
ORDER BY CreationDate DESC;
