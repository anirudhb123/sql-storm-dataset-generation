
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        SUM(CASE WHEN P.LastActivityDate > NOW() - INTERVAL 30 DAY THEN 1 ELSE 0 END) AS RecentActivity,
        MAX(P.LastActivityDate) AS LastActiveDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.Reputation, U.CreationDate
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        Questions,
        Answers,
        Wikis,
        RecentActivity,
        LastActiveDate,
        @rank := IF(@prev_reputation = Reputation, @rank + 1, 1) AS ReputationRank,
        @prev_reputation := Reputation
    FROM 
        UserStats, (SELECT @rank := 0, @prev_reputation := NULL) r
    ORDER BY 
        Reputation DESC
)
SELECT 
    T.UserId,
    U.DisplayName,
    T.Reputation,
    T.PostCount,
    T.Questions,
    T.Answers,
    T.Wikis,
    T.RecentActivity,
    T.LastActiveDate,
    @group_rank := IF(@prev_rank = T.ReputationRank, @group_rank + 1, 1) AS RankInGroup,
    @prev_rank := T.ReputationRank
FROM 
    TopUsers T, (SELECT @group_rank := 0, @prev_rank := NULL) g
JOIN 
    Users U ON T.UserId = U.Id
WHERE 
    T.ReputationRank <= 10
ORDER BY 
    T.Reputation DESC, RankInGroup;
