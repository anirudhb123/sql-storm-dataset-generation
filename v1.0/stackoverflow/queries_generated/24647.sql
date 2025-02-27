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
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStats
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        COALESCE(PH.RevisionGUID, 'N/A') AS LastGUID,
        RANK() OVER (ORDER BY P.ViewCount DESC) AS PopularityRank
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 10)
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
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
        RANK() OVER (ORDER BY P.ViewCount DESC, COALESCE(MC.CommentCount, 0) DESC) AS CombinedRank
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN MostCommentedPosts MC ON P.Id = MC.PostId
    WHERE P.ClosedDate IS NULL AND P.ViewCount > 100
)
SELECT 
    U.DisplayName,
    U.Reputation,
    FP.Title,
    FP.ViewCount,
    FP.CommentCount,
    FP.CombinedRank
FROM RankedUsers U
JOIN FilteredPosts FP ON U.QuestionCount > 5 -- Filtering users with more than 5 questions
WHERE U.Rank <= 10 -- Gets top users based on reputation
ORDER BY U.Rank, FP.CombinedRank
LIMIT 10;

/* This query provides an insightful overview by:
   1. Calculating user statistics including post counts and reputation.
   2. Ranking users based on their reputation.
   3. Selecting popular posts from the last year based on view counts, with an option to display the last revision GUID if available.
   4. Counting comments per post to provide additional metrics.
   5. Filtering posts that aren't closed and have a minimum view count.
   6. Finally, it provides the top 10 users with questions, showing their relevant statistics.
*/
