WITH RecursivePostCount AS (
    SELECT 
        Id,
        OwnerUserId,
        COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS AnswerCount
    FROM Posts
    GROUP BY Id, OwnerUserId
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(RPC.AnswerCount), 0) AS TotalAnswers,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews
    FROM Users U
    LEFT JOIN RecursivePostCount RPC ON U.Id = RPC.OwnerUserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUser AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalAnswers,
        TotalPosts,
        TotalViews,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM UserPostStats
),
RecentVotes AS (
    SELECT 
        V.UserId,
        P.Id AS PostId,
        P.Title,
        V.CreationDate,
        VT.Name AS VoteType,
        ROW_NUMBER() OVER (PARTITION BY V.UserId ORDER BY V.CreationDate DESC) AS VoteOrder
    FROM Votes V
    JOIN Posts P ON V.PostId = P.Id
    JOIN VoteTypes VT ON V.VoteTypeId = VT.Id
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalAnswers,
    TU.TotalViews,
    RV.PostId AS RecentPostId,
    RV.Title AS RecentPostTitle,
    RV.VoteType AS RecentVoteType,
    RV.CreationDate AS RecentVoteDate
FROM TopUser TU
LEFT JOIN RecentVotes RV ON TU.UserId = RV.UserId AND RV.VoteOrder = 1
WHERE TU.PostRank <= 10
ORDER BY TU.Reputation DESC, TU.UserId;
