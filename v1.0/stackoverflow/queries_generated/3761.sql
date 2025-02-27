WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserReputation
    WHERE 
        Reputation > 0
)
SELECT 
    U.Id,
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    COALESCE(B.Class, 0) AS BadgeClass,
    COALESCE(B.Name, 'No Badge') AS BadgeName
FROM 
    TopUsers U
LEFT JOIN 
    Badges B ON U.UserId = B.UserId AND B.Date = (
        SELECT MAX(B2.Date) 
        FROM Badges B2 
        WHERE B2.UserId = U.UserId
    )
WHERE 
    U.Rank <= 10
ORDER BY 
    U.Rank;
