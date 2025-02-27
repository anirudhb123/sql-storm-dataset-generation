WITH TagFrequency AS (
    SELECT
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS Frequency
    FROM
        Posts
    WHERE
        PostTypeId = 1 -- Questions only
    GROUP BY
        TagName
),
TopTags AS (
    SELECT
        TagName,
        Frequency,
        ROW_NUMBER() OVER (ORDER BY Frequency DESC) AS Rank
    FROM
        TagFrequency
    WHERE
        Frequency > 5 -- Only consider tags used more than 5 times
),
UserBadges AS (
    SELECT
        Users.DisplayName,
        COUNT(Badges.Id) AS BadgeCount,
        SUM(CASE WHEN Badges.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN Badges.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN Badges.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM
        Users
    LEFT JOIN
        Badges ON Users.Id = Badges.UserId
    GROUP BY
        Users.DisplayName
),
TopUsers AS (
    SELECT
        Users.DisplayName,
        Users.Reputation,
        UserBadges.BadgeCount,
        UserBadges.GoldCount,
        UserBadges.SilverCount,
        UserBadges.BronzeCount,
        ROW_NUMBER() OVER (ORDER BY Users.Reputation DESC) AS Ranking
    FROM
        Users
    JOIN
        UserBadges ON Users.DisplayName = UserBadges.DisplayName
    WHERE
        Users.Reputation > 1000 -- Arbitrarily considering users with reputation greater than 1000
),
PopularQuestions AS (
    SELECT
        Posts.Title,
        Posts.ViewCount,
        Posts.AnswerCount,
        Posts.Score,
        Posts.CreationDate,
        Posts.Tags,
        ROW_NUMBER() OVER (ORDER BY Posts.ViewCount DESC) AS PopularityRank
    FROM
        Posts
    WHERE
        PostTypeId = 1 -- Questions only
)
SELECT
    tt.TagName,
    tt.Frequency,
    tu.DisplayName AS TopUser,
    tu.Reputation,
    tu.BadgeCount,
    pu.Title AS PopularQuestion,
    pu.ViewCount,
    pu.AnswerCount,
    pu.CreationDate
FROM
    TopTags tt
JOIN
    TopUsers tu ON 1 = 1 -- Cross join to relate every tag with the top users
JOIN
    PopularQuestions pu ON pu.PopularityRank <= 10 -- Top 10 popular questions
ORDER BY
    tt.Frequency DESC, 
    tu.Reputation DESC, 
    pu.ViewCount DESC;
