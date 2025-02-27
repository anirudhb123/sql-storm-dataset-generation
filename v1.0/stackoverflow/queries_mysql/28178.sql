
WITH TagUsage AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    INNER JOIN (
        SELECT a.N + b.N * 10 + 1 AS n
        FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS a
            CROSS JOIN 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS b
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE
        PostTypeId = 1
    GROUP BY
        TagName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        @rownum := @rownum + 1 AS Rank
    FROM
        TagUsage, (SELECT @rownum := 0) r
    ORDER BY
        PostCount DESC
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN
        Comments c ON u.Id = c.UserId
    LEFT JOIN
        Votes v ON u.Id = v.UserId AND v.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = 1)
    GROUP BY
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        QuestionsAsked,
        CommentsMade,
        UpvotesReceived,
        @rownum := @rownum + 1 AS Rank
    FROM
        UserActivity, (SELECT @rownum := 0) r
    WHERE
        QuestionsAsked > 0
)
SELECT
    tg.TagName,
    tg.PostCount AS NumberOfQuestions,
    tu.DisplayName AS TopUser,
    tu.QuestionsAsked,
    tu.CommentsMade,
    tu.UpvotesReceived
FROM
    TopTags tg
JOIN
    TopUsers tu ON tg.Rank = tu.Rank
WHERE
    tg.Rank <= 10
ORDER BY
    tg.PostCount DESC, tu.UpvotesReceived DESC;
