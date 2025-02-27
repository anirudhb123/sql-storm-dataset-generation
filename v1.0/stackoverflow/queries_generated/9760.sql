WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        QuestionCount,
        CommentCount,
        LastPostDate,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM UserActivity
),
MostActiveTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>,<')::int[])
    GROUP BY t.TagName
    ORDER BY PostCount DESC
    LIMIT 5
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.AnswerCount,
    tu.QuestionCount,
    tu.CommentCount,
    mt.TagName,
    mt.PostCount AS TagPostCount
FROM TopUsers tu
JOIN MostActiveTags mt ON mt.TagName IN (
    SELECT UNNEST(string_to_array(substring((SELECT Tags FROM Posts WHERE OwnerUserId = tu.UserId LIMIT 1), 2, length((SELECT Tags FROM Posts WHERE OwnerUserId = tu.UserId LIMIT 1))-2), '>,<'))
)
WHERE tu.Rank <= 10
ORDER BY tu.PostCount DESC, mt.PostCount DESC;
