
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        @rownum := @rownum + 1 AS Rank
    FROM 
        UserStatistics, (SELECT @rownum := 0) r
    ORDER BY 
        Reputation DESC, TotalUpVotes DESC
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.OwnerUserId
),
UserPostComments AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS UserPostCount,
        SUM(COALESCE(C.Score, 0)) AS TotalCommentScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    RP.Title AS RecentPostTitle,
    RP.CommentCount,
    CASE 
        WHEN U.Reputation IS NULL THEN 'Unknown'
        WHEN U.Reputation >= 1000 THEN 'Elite'
        ELSE 'Regular' 
    END AS UserTier,
    (SELECT COUNT(*) FROM UserPostComments) AS TotalUserComments,
    U.TotalUpVotes - U.TotalDownVotes AS NetVotes
FROM 
    UserStatistics U
LEFT JOIN 
    TopUsers TU ON U.UserId = TU.UserId
LEFT JOIN 
    RecentPosts RP ON U.UserId = RP.OwnerUserId
WHERE 
    TU.Rank <= 10
ORDER BY 
    U.Reputation DESC;
