
WITH PostTags AS (
    SELECT
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag
    FROM
        Posts p
    INNER JOIN (
        SELECT 
            1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
            UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
            UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
        ) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE
        p.PostTypeId = 1
),
PopularTags AS (
    SELECT
        Tag,
        COUNT(*) AS TagCount
    FROM
        PostTags
    GROUP BY
        Tag
    HAVING
        COUNT(*) > 10  
),
RecentUserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.LastActivityDate >= NOW() - INTERVAL 30 DAY THEN 1 ELSE 0 END) AS RecentActivityCount,
        AVG(TIMESTAMPDIFF(SECOND, p.CreationDate, p.LastActivityDate)) AS AvgPostAge
    FROM
        Users u
    JOIN Posts p ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1
    GROUP BY
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        QuestionCount,
        RecentActivityCount,
        AvgPostAge,
        @rank := IF(@prev_question_count = QuestionCount, @rank, @rank + 1) AS UserRank,
        @prev_question_count := QuestionCount
    FROM
        RecentUserActivity
    CROSS JOIN (SELECT @rank := 0, @prev_question_count := NULL) AS r
    WHERE
        RecentActivityCount > 0
)
SELECT
    t.Tag,
    t.TagCount,
    tu.DisplayName,
    tu.QuestionCount,
    tu.RecentActivityCount,
    tu.AvgPostAge
FROM
    PopularTags t
JOIN
    TopUsers tu ON tu.QuestionCount > 5  
ORDER BY
    t.TagCount DESC, tu.QuestionCount DESC
LIMIT 10;
