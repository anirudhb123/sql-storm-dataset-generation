
WITH TagCounts AS (
    SELECT
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS TagFrequency
    FROM
        Posts p
    INNER JOIN (
        SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE
        p.PostTypeId = 1  
    GROUP BY
        p.Id, TagName
),
TopTags AS (
    SELECT
        TagName,
        SUM(TagFrequency) AS TotalCount
    FROM
        TagCounts
    GROUP BY
        TagName
    ORDER BY
        TotalCount DESC
    LIMIT 10
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount,
        AVG(TIMESTAMPDIFF(SECOND, u.CreationDate, p.LastActivityDate)) / 3600.0 AS AvgActivityDuration_Hours
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN
        Comments c ON u.Id = c.UserId
    LEFT JOIN
        Votes v ON v.UserId = u.Id
    GROUP BY
        u.Id
),
TopUsers AS (
    SELECT
        ua.UserId,
        ua.QuestionCount,
        ua.CommentCount,
        ua.VoteCount,
        ua.AvgActivityDuration_Hours,
        @rank := @rank + 1 AS Rank
    FROM
        UserActivity ua, (SELECT @rank := 0) r
    ORDER BY
        ua.QuestionCount DESC, ua.VoteCount DESC
)
SELECT
    tu.UserId,
    u.DisplayName,
    tu.QuestionCount,
    tu.CommentCount,
    tu.VoteCount,
    tu.AvgActivityDuration_Hours,
    tt.TagName
FROM
    TopUsers tu
JOIN
    Users u ON tu.UserId = u.Id
CROSS JOIN
    TopTags tt
WHERE
    tu.Rank <= 10  
ORDER BY
    tu.Rank,
    tt.TotalCount DESC;
