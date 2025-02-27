
WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        BadgeCount,
        @rank := IF(@prev_reputation = Reputation AND @prev_postcount = PostCount, @rank, @rank + 1) AS Rank,
        @prev_reputation := Reputation,
        @prev_postcount := PostCount
    FROM 
        UserPostCounts, (SELECT @rank := 0, @prev_reputation := NULL, @prev_postcount := NULL) AS vars
    ORDER BY 
        Reputation DESC, PostCount DESC
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    BadgeCount,
    Rank
FROM 
    ActiveUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
