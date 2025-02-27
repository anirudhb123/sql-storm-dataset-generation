WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.UpVotes > 0 THEN P.UpVotes ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN P.DownVotes > 0 THEN P.DownVotes ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        Questions,
        Answers,
        TotalUpVotes,
        TotalDownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
),
TopBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)

SELECT 
    RU.DisplayName,
    RU.Reputation,
    RU.PostCount,
    RU.Questions,
    RU.Answers,
    RU.TotalUpVotes,
    RU.TotalDownVotes,
    TB.BadgeNames
FROM 
    RankedUsers RU
LEFT JOIN 
    TopBadges TB ON RU.UserId = TB.UserId
WHERE 
    RU.ReputationRank <= 10
ORDER BY 
    RU.Reputation DESC,
    RU.PostCount DESC;
