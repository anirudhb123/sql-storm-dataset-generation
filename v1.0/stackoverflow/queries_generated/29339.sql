WITH TagCount AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts
    CROSS JOIN 
        (SELECT UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '> <'))::varchar[]) AS TagName 
         FROM Posts) AS TagList
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCount
    WHERE 
        PostCount > 0
),
UserBadgeDetails AS (
    SELECT 
        U.DisplayName AS UserName,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.DisplayName
),
TopUsers AS (
    SELECT 
        UserName,
        TotalBadges
    FROM 
        UserBadgeDetails
    WHERE 
        TotalBadges > 0
    ORDER BY 
        TotalBadges DESC
    LIMIT 10
)
SELECT 
    T.TagName,
    T.PostCount AS TotalPosts,
    T.QuestionCount,
    T.AnswerCount,
    U.UserName,
    U.TotalBadges AS UserBadges
FROM 
    TopTags T
JOIN 
    TopUsers U ON T.TagRank <= 10
ORDER BY 
    T.PostCount DESC,
    U.TotalBadges DESC;
