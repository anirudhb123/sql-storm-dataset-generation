WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesEarned
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        UpVotes,
        DownVotes,
        BadgesEarned,
        RANK() OVER (ORDER BY TotalPosts DESC, UpVotes DESC) AS PostRank
    FROM 
        UserActivity
)
SELECT 
    T.DisplayName,
    T.TotalPosts,
    T.TotalComments,
    T.UpVotes,
    T.DownVotes,
    T.BadgesEarned
FROM 
    TopUsers T
WHERE 
    T.PostRank <= 10
ORDER BY 
    T.UpVotes DESC, T.TotalPosts DESC;
