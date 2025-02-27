
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        @rank := @rank + 1 AS Rank
    FROM UserStats, (SELECT @rank := 0) AS r
    ORDER BY Reputation DESC
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        COALESCE(PH.RevisionGUID, 'N/A') AS LastGUID,
        @popularityRank := @popularityRank + 1 AS PopularityRank
    FROM Posts P, (SELECT @popularityRank := 0) AS r
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 10)
    WHERE P.CreationDate >= CURDATE() - INTERVAL 1 YEAR
),
MostCommentedPosts AS (
    SELECT 
        PostId,
        COUNT(C.Id) AS CommentCount
    FROM Comments C
    GROUP BY PostId
),
FilteredPosts AS (
    SELECT 
        P.Title,
        P.Body,
        P.ViewCount,
        COALESCE(MC.CommentCount, 0) AS CommentCount,
        U.DisplayName AS OwnerDisplayName,
        @combinedRank := @combinedRank + 1 AS CombinedRank
    FROM Posts P, (SELECT @combinedRank := 0) AS r
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN MostCommentedPosts MC ON P.Id = MC.PostId
    WHERE P.ClosedDate IS NULL AND P.ViewCount > 100
    ORDER BY P.ViewCount DESC, COALESCE(MC.CommentCount, 0) DESC
)
SELECT 
    U.DisplayName,
    U.Reputation,
    FP.Title,
    FP.ViewCount,
    FP.CommentCount,
    FP.CombinedRank
FROM RankedUsers U
JOIN FilteredPosts FP ON U.QuestionCount > 5 
WHERE U.Rank <= 10 
ORDER BY U.Rank, FP.CombinedRank
LIMIT 10;
