WITH RecursiveUserHierarchy AS (
    SELECT U.Id, U.Reputation, U.DisplayName, U.Location, 1 AS Level
    FROM Users U
    WHERE U.Reputation > 1000 -- Start with users having more than 1000 reputation

    UNION ALL

    SELECT U.Id, U.Reputation, U.DisplayName, U.Location, Level + 1
    FROM Users U
    JOIN Votes V ON U.Id = V.UserId
    JOIN RecursiveUserHierarchy R ON V.PostId IN (
        SELECT P.Id
        FROM Posts P
        WHERE P.OwnerUserId = R.Id
    )
    WHERE Level < 5  -- Limit to 5 levels in hierarchy
),
FilteredPosts AS (
    SELECT P.Id, P.Title, P.ViewCount, P.Score, U.DisplayName AS OwnerDisplayName
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '1 month' -- Posts created in the last month
      AND P.AnswerCount > 0 -- Only considering questions with answers
),
RankedPosts AS (
    SELECT FP.*, 
           ROW_NUMBER() OVER (PARTITION BY FP.OwnerDisplayName ORDER BY FP.ViewCount DESC) AS RankByViews,
           SUM(FP.Score) OVER (PARTITION BY FP.OwnerDisplayName) AS TotalScore
    FROM FilteredPosts FP
),
MaxRankedScores AS (
    SELECT OwnerDisplayName, MAX(TotalScore) AS MaxScore
    FROM RankedPosts
    WHERE RankByViews <= 3 -- Top 3 posts by views
    GROUP BY OwnerDisplayName
),
CloseReasons AS (
    SELECT DISTINCT PH.PostId, C.Name AS CloseReason
    FROM PostHistory PH
    JOIN CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE PH.PostHistoryTypeId = 10 -- Only considering closed posts
)
SELECT R.OwnerDisplayName,
       COUNT(DISTINCT R.Id) AS PostCount,
       NCO.CloseReason,
       U.Reputation,
       COALESCE(MR.MaxScore, 0) AS MaxScore
FROM RankedPosts R
LEFT JOIN CloseReasons NCO ON R.Id = NCO.PostId
LEFT JOIN RecursiveUserHierarchy U ON R.OwnerDisplayName = U.DisplayName
WHERE R.RankByViews <= 3 -- Only top ranked posts
GROUP BY R.OwnerDisplayName, NCO.CloseReason, U.Reputation, MR.MaxScore
ORDER BY PostCount DESC, MaxScore DESC;
