WITH UserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikis,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        TagWikis,
        TotalViews,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UserPosts
    WHERE 
        TotalPosts > 0
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
TopUserBadges AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.TotalPosts,
        U.Questions,
        U.Answers,
        U.TagWikis,
        U.TotalViews,
        U.AverageScore,
        COALESCE(UB.TotalBadges, 0) AS TotalBadges,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges
    FROM 
        TopUsers U
    LEFT JOIN 
        UserBadges UB ON U.UserId = UB.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    TagWikis,
    TotalViews,
    AverageScore,
    TotalBadges,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    TopUserBadges
WHERE 
    Rank <= 10
ORDER BY 
    TotalPosts DESC;

This SQL query ranks users based on their activity within the posts they authored, such as total posts, questions, answers, and tag wikis. Additionally, it retrieves information about earned badges, including counts for gold, silver, and bronze badges, and outputs the ten most active users.
