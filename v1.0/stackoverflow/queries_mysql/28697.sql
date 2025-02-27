
WITH TagUsage AS (
    SELECT
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '> <', numbers.n), '> <', -1)) AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
        SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '> <', '')) >= numbers.n - 1
    WHERE
        PostTypeId = 1  
    GROUP BY
        TagName
),
PopularTags AS (
    SELECT
        TagName,
        PostCount,
        @rank := IF(@prevPostCount = PostCount, @rank, @rank + 1) AS TagRank,
        @prevPostCount := PostCount
    FROM
        TagUsage, (SELECT @rank := 0, @prevPostCount := NULL) AS vars
    ORDER BY
        PostCount DESC
),
UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        DisplayName,
        QuestionCount,
        UpVotes,
        DownVotes,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        @userRank := IF(@prevQuestionCount = QuestionCount, @userRank, @userRank + 1) AS UserRank,
        @prevQuestionCount := QuestionCount
    FROM
        UserEngagement, (SELECT @userRank := 0, @prevQuestionCount := NULL) AS vars
    ORDER BY
        QuestionCount DESC
)
SELECT 
    pu.TagName,
    pu.PostCount,
    tu.DisplayName AS TopUser,
    tu.QuestionCount,
    tu.UpVotes,
    tu.DownVotes,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges
FROM 
    PopularTags pu
JOIN 
    TopUsers tu ON pu.TagRank = 1 
ORDER BY 
    pu.PostCount DESC, tu.QuestionCount DESC;
