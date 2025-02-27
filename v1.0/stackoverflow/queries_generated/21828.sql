WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
FinalMetrics AS (
    SELECT 
        TB.UserId,
        TB.DisplayName,
        TB.TotalBadges,
        TB.GoldBadges,
        TB.SilverBadges,
        TB.BronzeBadges,
        PU.Reputation,
        PU.ReputationRank,
        PS.TotalPosts,
        PS.TotalQuestions,
        PS.TotalScore
    FROM 
        UserBadges TB
    JOIN 
        TopUsers PU ON TB.UserId = PU.Id
    LEFT JOIN 
        PostStats PS ON TB.UserId = PS.OwnerUserId
)
SELECT
    COALESCE(DISTINCT U.DisplayName, 'Unknown User') AS UserName,
    COALESCE(F.TotalBadges, 0) AS BadgeCount,
    COALESCE(F.GoldBadges, 0) AS GoldCount,
    COALESCE(F.SilverBadges, 0) AS SilverCount,
    COALESCE(F.BronzeBadges, 0) AS BronzeCount,
    F.Reputation,
    F.ReputationRank,
    COALESCE(F.TotalPosts, 0) AS PostCount,
    COALESCE(F.TotalQuestions, 0) AS QuestionCount,
    COALESCE(F.TotalScore, 0) AS Score,
    STRING_AGG(DISTINCT T.TagName, ', ') AS TagsUsed
FROM 
    FinalMetrics F
LEFT JOIN 
    Posts P ON F.UserId = P.OwnerUserId
LEFT JOIN 
    Tags T ON POSITION('>' || T.TagName || '<' IN '<' || P.Tags || '>') > 0
WHERE 
    F.TotalBadges IS NOT NULL 
    AND F.ReputationRank < 11 -- Top 10 users 
GROUP BY 
    F.UserId, F.DisplayName, F.TotalBadges, F.GoldBadges, F.SilverBadges, F.BronzeBadges,
    F.Reputation, F.ReputationRank
ORDER BY 
    F.Reputation DESC, F.TotalBadges DESC;

This SQL query does the following:
- It aggregates users' badges and rankings.
- It calculates statistics on users' posts.
- It fetches user information, incorporating outer joins and string aggregation for tags associated with the users’ posts.
- The unnecessary noise (users with null badges) is filtered out while also ensuring unknown users are labeled correctly.
- It employs window functions to rank users based on reputation and limits results to the top 10 users while displaying detailed badge counts and post statistics.
