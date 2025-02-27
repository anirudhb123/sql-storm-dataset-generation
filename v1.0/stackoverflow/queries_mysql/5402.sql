
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users U 
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        UpVotes,
        DownVotes,
        BadgeCount,
        @rank:=@rank + 1 AS Rank
    FROM 
        UserStats, (SELECT @rank := 0) r
    ORDER BY 
        Reputation DESC
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.CommentCount,
    U.UpVotes,
    U.DownVotes,
    U.BadgeCount,
    CASE 
        WHEN Rank <= 10 THEN 'Top Contributor' 
        ELSE 'Regular User' 
    END AS UserCategory
FROM 
    TopUsers U
WHERE 
    U.PostCount > 5
ORDER BY 
    U.Reputation DESC, 
    U.PostCount DESC;
