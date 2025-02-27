
WITH RecursiveUserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        @row_num := @row_num + 1 AS UserRank
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    CROSS JOIN (SELECT @row_num := 0) AS r
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
        @post_rank := @post_rank + 1 AS PostRank
    FROM RecursiveUserActivity
    CROSS JOIN (SELECT @post_rank := 0) AS r
),
ClosedQuestions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.CreationDate AS ClosedDate,
        U.DisplayName AS ClosedBy,
        COUNT(V.Id) AS TotalVotes
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10  
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Users U ON PH.UserId = U.Id
    WHERE P.PostTypeId = 1  
    GROUP BY P.Id, P.Title, PH.CreationDate, U.DisplayName
),
TopClosedQuestions AS (
    SELECT 
        PostId,
        Title,
        ClosedDate,
        ClosedBy,
        TotalVotes,
        @vote_rank := @vote_rank + 1 AS RankByVotes
    FROM ClosedQuestions
    CROSS JOIN (SELECT @vote_rank := 0) AS r
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
LEFT JOIN TopClosedQuestions T ON U.UserId = T.PostId  
WHERE U.UserRank <= 10  
  AND (T.ClosedDate IS NULL OR T.ClosedBy IS NOT NULL)  
ORDER BY U.TotalBounty DESC, U.UserRank;
