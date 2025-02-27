
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(P.ViewCount) AS TotalViews,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName
),
BadgeSummary AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.QuestionCount,
        UA.TotalViews,
        UA.Upvotes,
        UA.Downvotes,
        BS.GoldBadges,
        BS.SilverBadges,
        BS.BronzeBadges,
        @rank := IF(@prev_question_count = UA.QuestionCount AND @prev_total_views = UA.TotalViews, @rank, @rank + 1) AS Rank,
        @prev_question_count := UA.QuestionCount,
        @prev_total_views := UA.TotalViews
    FROM 
        UserActivity UA
    LEFT JOIN 
        BadgeSummary BS ON UA.UserId = BS.UserId,
        (SELECT @rank := 0, @prev_question_count := NULL, @prev_total_views := NULL) AS vars
    ORDER BY 
        UA.QuestionCount DESC, UA.TotalViews DESC
)
SELECT 
    UserId,
    DisplayName,
    QuestionCount,
    TotalViews,
    Upvotes,
    Downvotes,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    Rank
FROM 
    TopUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
