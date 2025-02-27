WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        B.Name AS BadgeName,
        B.Class,
        1 AS BadgeLevel
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        B.Class = 1  -- Gold badges

    UNION ALL

    SELECT 
        U.Id,
        U.Reputation,
        B.Name,
        B.Class,
        UB.BadgeLevel + 1
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
    JOIN 
        UserBadges UB ON U.Id = UB.UserId
    WHERE 
        B.Class = 2  -- Silver badges
),

PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),

TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        PS.TotalPosts,
        PS.QuestionCount,
        PS.AnswerCount,
        PS.AcceptedAnswers,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges
    FROM 
        Users U
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, PS.TotalPosts, PS.QuestionCount, PS.AnswerCount, PS.AcceptedAnswers
    HAVING 
        PS.TotalPosts > 0
    ORDER BY 
        U.Reputation DESC
    LIMIT 10
)

SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.AcceptedAnswers,
    UB.BadgeName,
    UB.BadgeLevel
FROM 
    TopUsers TU
LEFT JOIN 
    UserBadges UB ON TU.UserId = UB.UserId
WHERE 
    TU.Reputation >= (
        SELECT 
            AVG(Reputation) 
        FROM 
            TopUsers
    )
ORDER BY 
    TU.Reputation DESC,
    UB.BadgeLevel DESC;
