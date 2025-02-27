WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.Score ELSE 0 END) AS QuestionScore,
        SUM(CASE WHEN P.PostTypeId = 2 THEN P.Score ELSE 0 END) AS AnswerScore,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionScore,
        AnswerScore,
        TotalBounties,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        COUNT(C) AS CommentCount,
        MAX(CreationDate) AS LastCommentDate
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.Title, P.ViewCount, P.Score
    HAVING COUNT(C) > 0
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.Comment AS CloseComment,
        PH.UserDisplayName AS ClosedBy
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE PHT.Name = 'Post Closed'
),
UserPostSummary AS (
    SELECT 
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(CP.CloseComment, '') IS NOT NULL) AS ClosedPostsCount,
        SUM(CASE WHEN T.ReputationRank <= 10 THEN 1 ELSE 0 END) AS TopTenRankedContributors
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN ClosedPostHistory CP ON P.Id = CP.PostId
    LEFT JOIN RankedUsers T ON U.Id = T.UserId
    GROUP BY U.DisplayName
)

SELECT 
    U.DisplayName,
    UPS.TotalPosts,
    UPS.ClosedPostsCount,
    UPS.TopTenRankedContributors,
    TH.PostId,
    TH.Title AS TopPostTitle,
    TH.ViewCount,
    TH.Score AS TopPostScore,
    TH.CommentCount,
    TH.LastCommentDate
FROM UserPostSummary UPS
JOIN RankedUsers R ON UPS.DisplayName = R.DisplayName
JOIN TopPosts TH ON TH.Score = (SELECT MAX(Score) FROM TopPosts WHERE CommentCount > 0)
WHERE R.ReputationRank <= 10
ORDER BY UPS.TotalPosts DESC, R.Reputation DESC;
