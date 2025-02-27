WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN B.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentRN
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '6 months'
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    COALESCE(RP.Title, 'No Recent Posts') AS RecentPostTitle,
    COALESCE(RP.CreationDate, 'N/A') AS RecentPostDate,
    COALESCE(RP.ViewCount, 0) AS RecentPostViewCount,
    COALESCE(RP.Score, 0) AS RecentPostScore,
    US.PostCount,
    US.QuestionCount,
    US.AnswerCount,
    US.BadgeCount
FROM 
    UserStats US
LEFT JOIN 
    RecentPosts RP ON US.UserId = RP.OwnerUserId AND RP.RecentRN = 1
WHERE 
    US.Reputation > 1000
ORDER BY 
    US.Reputation DESC 
LIMIT 50;
