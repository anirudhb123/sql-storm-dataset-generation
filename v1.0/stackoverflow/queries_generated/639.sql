WITH UserStats AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN P.CreationDate >= CURRENT_DATE - INTERVAL '30 days' THEN 1 ELSE 0 END) AS RecentPosts
    FROM 
        Users U 
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 
TopBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS Badges
    FROM 
        Badges B
    WHERE 
        B.Class = 1 OR B.Class = 2  -- Gold and Silver badges
    GROUP BY 
        B.UserId
), 
RecentPostsRanked AS (
    SELECT 
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '7 days'
)

SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(TB.Badges, 'No Badges') AS Badges,
    US.PostCount,
    US.AcceptedAnswers,
    US.RecentPosts,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostDate
FROM 
    UserStats US
LEFT JOIN 
    TopBadges TB ON US.Id = TB.UserId
LEFT JOIN 
    RecentPostsRanked RP ON US.Id = RP.OwnerUserId AND RP.RecentRank = 1
WHERE 
    US.Reputation > 5000
ORDER BY 
    US.Reputation DESC;
