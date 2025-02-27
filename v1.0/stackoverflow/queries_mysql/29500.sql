
WITH TagCounts AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL 
        SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL 
        SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
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
        @row_num := @row_num + 1 AS TagRank
    FROM
        TagCounts, (SELECT @row_num := 0) r
    WHERE
        PostCount > 10 
    ORDER BY
        PostCount DESC
),
UserScores AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionsAnswered,
        COUNT(DISTINCT c.Id) AS CommentsMade
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2 
    LEFT JOIN
        Comments c ON u.Id = c.UserId
    GROUP BY
        u.Id, u.Reputation
),
HighScoringUsers AS (
    SELECT
        UserId,
        Reputation,
        QuestionsAnswered,
        CommentsMade,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM
        UserScores
    WHERE
        Reputation > 1000 
)
SELECT
    t.TagName,
    t.PostCount,
    u.UserId,
    u.Reputation,
    u.QuestionsAnswered,
    u.CommentsMade
FROM
    TopTags t
JOIN
    HighScoringUsers u ON EXISTS (
        SELECT 1
        FROM Posts p
        WHERE p.Title LIKE CONCAT('%', t.TagName, '%')
        AND p.OwnerUserId = u.UserId
    )
ORDER BY
    t.PostCount DESC, u.Reputation DESC
LIMIT 20;
