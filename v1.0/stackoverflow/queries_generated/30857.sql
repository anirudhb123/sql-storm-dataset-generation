WITH RecursiveUserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(V.BountyAmount), 0) DESC) AS UserRank
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName
),
UserStatistics AS (
    SELECT 
        UserId,
        DisplayName,
        TotalBounty,
        TotalUpVotes,
        TotalDownVotes,
        TotalPosts,
        TotalComments,
        UserRank,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM RecursiveUserActivity
),
ClosedQuestions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.CreationDate AS ClosedDate,
        U.DisplayName AS ClosedBy,
        COUNT(V.Id) AS TotalVotes
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10  -- Post Closed
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Users U ON PH.UserId = U.Id
    WHERE P.PostTypeId = 1  -- Only Questions
    GROUP BY P.Id, P.Title, PH.CreationDate, U.DisplayName
),
TopClosedQuestions AS (
    SELECT 
        PostId,
        Title,
        ClosedDate,
        ClosedBy,
        TotalVotes,
        RANK() OVER (ORDER BY TotalVotes DESC) AS RankByVotes
    FROM ClosedQuestions
)
SELECT 
    U.DisplayName AS UserName,
    U.TotalBounty,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.TotalPosts,
    U.TotalComments,
    T.Title AS TopClosedQuestionTitle,
    T.ClosedDate,
    T.ClosedBy
FROM UserStatistics U
LEFT JOIN TopClosedQuestions T ON U.UserId = T.PostId  -- Join with top closed questions
WHERE U.UserRank <= 10  -- We are interested in top 10 users
  AND (T.ClosedDate IS NULL OR T.ClosedBy IS NOT NULL)  -- Include only valid closed questions
ORDER BY U.TotalBounty DESC, U.UserRank;
