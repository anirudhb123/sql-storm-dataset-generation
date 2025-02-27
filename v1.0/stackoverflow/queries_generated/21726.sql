WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.UserId,
        COUNT(PH.PostId) AS ClosedPostCount,
        MIN(PH.CreationDate) AS FirstCloseDate,
        MAX(PH.CreationDate) AS LastCloseDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Considering only closed and reopened posts
    GROUP BY 
        PH.UserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(UBS.TotalBadges, 0) AS TotalBadges,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(CP.ClosedPostCount, 0) AS ClosedPosts,
        CASE 
            WHEN COALESCE(PS.TotalPosts, 0) = 0 THEN 0
            ELSE COALESCE(PS.TotalScore, 0) / COALESCE(PS.TotalPosts, 1)
        END AS ScorePerPost
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeStats UBS ON U.Id = UBS.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN 
        ClosedPosts CP ON U.Id = CP.UserId
    WHERE 
        U.Reputation > 50 -- Only considering users with more than 50 reputation
    ORDER BY 
        ScorePerPost DESC,
        TotalBadges DESC
),
UserRanks AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY ScorePerPost DESC, TotalBadges DESC) AS Rank
    FROM 
        TopUsers
)
SELECT 
    UR.Rank,
    UR.DisplayName,
    UR.TotalBadges,
    UR.TotalPosts,
    UR.ClosedPosts,
    UR.ScorePerPost
FROM 
    UserRanks UR
WHERE 
    UR.Rank <= 10 -- Top 10 users
    AND (UR.TotalPosts > 5 OR UR.TotalBadges > 3)
ORDER BY 
    UR.Rank;

This SQL query performs the following actions:
1. It creates several Common Table Expressions (CTEs) to gather user badge statistics, post statistics, and closed post information.
2. It aggregates data to evaluate user activity, total badges, and post scores.
3. It ranks users based on their performance metrics, filtering to include only those with a minimum reputation, before selecting the top 10 users based on defined performance criteria. 
4. It includes intricate logic, such as handling NULL values with COALESCE, and filtering on multiple conditions regarding users' total badges and posts.
