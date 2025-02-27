WITH TagUsage AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts 
    WHERE 
        PostTypeId = 1 -- Only count tags from Questions
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagUsage
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 0 -- Only consider users with positive reputation
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AnswerCount,
        DENSE_RANK() OVER (ORDER BY QuestionCount DESC, AnswerCount DESC) AS UserRank
    FROM 
        UserActivity
),
BadgesSummary AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
FinalReport AS (
    SELECT 
        U.DisplayName,
        T.TagName,
        T.PostCount,
        UA.QuestionCount,
        UA.AnswerCount,
        BS.BadgeCount,
        BS.GoldBadges,
        BS.SilverBadges,
        BS.BronzeBadges
    FROM 
        TopTags T 
    JOIN 
        TopUsers UA ON UA.UserRank <= 10 -- Join only top 10 users
    JOIN 
        BadgesSummary BS ON UA.UserId = BS.UserId
    ORDER BY 
        T.PostCount DESC, UA.QuestionCount DESC
)
SELECT 
    * 
FROM 
    FinalReport
WHERE 
    TagName IN (SELECT TagName FROM TopTags WHERE TagRank <= 5) -- Filter for top 5 tags
ORDER BY 
    PostCount DESC, QuestionCount DESC;
