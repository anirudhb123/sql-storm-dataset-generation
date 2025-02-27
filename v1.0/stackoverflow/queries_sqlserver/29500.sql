
WITH TagCounts AS (
    SELECT
        value AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE
        PostTypeId = 1 
    GROUP BY
        value
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM
        TagCounts
    WHERE
        PostCount > 10 
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
        WHERE p.Title LIKE '%' + t.TagName + '%'
        AND p.OwnerUserId = u.UserId
    )
ORDER BY
    t.PostCount DESC, u.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
