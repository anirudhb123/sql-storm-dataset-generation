WITH UserReputationStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(COALESCE(B.Class, 0)) AS BadgeCount,
        AVG(COALESCE(VoteCount.VoteCount, 0)) AS AvgVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) AS VoteCount ON P.Id = VoteCount.PostId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        CommentCount,
        BadgeCount,
        AvgVotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputationStats
)
SELECT 
    U.DisplayName,
    T.Reputation,
    T.PostCount,
    T.CommentCount,
    T.BadgeCount,
    T.AvgVotes
FROM 
    TopUsers T
JOIN 
    Users U ON T.UserId = U.Id
WHERE 
    T.ReputationRank <= 10
ORDER BY 
    T.Reputation DESC;
