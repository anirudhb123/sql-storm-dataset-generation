
WITH RECURSIVE UserPostCount AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        PostCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM UserPostCount
    WHERE PostCount > 0
),
TagStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(t.Tag) AS TagCount
    FROM Posts p
    LEFT JOIN (
        SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
        FROM (
            SELECT a.N + b.N * 10 + 1 n
            FROM 
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
        ) numbers 
        WHERE numbers.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1
    ) t ON true
    WHERE p.OwnerUserId IS NOT NULL
    GROUP BY p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        t.UserId,
        t.PostCount,
        t.QuestionCount,
        t.AnswerCount,
        COALESCE(ts.TagCount, 0) AS TagCount
    FROM TopUsers t
    LEFT JOIN TagStats ts ON t.UserId = ts.OwnerUserId
)
SELECT 
    u.DisplayName,
    c.PostCount,
    c.QuestionCount,
    c.AnswerCount,
    c.TagCount,
    c.QuestionCount * 1.0 / NULLIF(c.PostCount, 0) AS QuestionRatio,
    CASE 
        WHEN c.TagCount > 10 THEN 'Highly Active Tagger'
        ELSE 'Moderate Tagger'
    END AS TaggingBehavior,
    COALESCE(SUM(b.Class), 0) AS BadgeCount
FROM CombinedStats c
JOIN Users u ON c.UserId = u.Id
LEFT JOIN Badges b ON u.Id = b.UserId
WHERE u.Reputation > 100
GROUP BY u.DisplayName, c.PostCount, c.QuestionCount, c.AnswerCount, c.TagCount
ORDER BY c.PostCount DESC
LIMIT 10;
