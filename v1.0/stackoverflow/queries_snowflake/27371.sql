
WITH TagCounts AS (
    SELECT
        p.Id AS PostId,
        TRIM(value) AS TagName,
        COUNT(*) AS TagFrequency
    FROM
        Posts p,
        TABLE(FLATTEN(INPUT => SPLIT(SUBSTR(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))) AS t
    WHERE
        p.PostTypeId = 1  
    GROUP BY
        p.Id, TRIM(value)
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
        AVG(DATEDIFF('hour', u.CreationDate, p.LastActivityDate)) AS AvgActivityDuration_Hours
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
        ROW_NUMBER() OVER (ORDER BY ua.QuestionCount DESC, ua.VoteCount DESC) AS Rank
    FROM
        UserActivity ua
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
