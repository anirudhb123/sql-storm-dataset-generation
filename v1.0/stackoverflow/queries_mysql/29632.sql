
WITH TagCount AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM
        Posts
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
        UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE
        PostTypeId = 1 
    GROUP BY
        Tag
),
UserParticipation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS OwnedQuestions,
        SUM(CASE WHEN ph.PostId IS NOT NULL THEN 1 ELSE 0 END) AS EditedQuestions
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5) 
    GROUP BY
        u.Id, u.DisplayName
),
TopParticipants AS (
    SELECT
        UserId,
        DisplayName,
        QuestionCount,
        OwnedQuestions,
        EditedQuestions,
        @rank := @rank + 1 AS Rank
    FROM
        UserParticipation, (SELECT @rank := 0) r
    WHERE
        QuestionCount > 0
    ORDER BY
        QuestionCount DESC
),
TopTags AS (
    SELECT
        Tag,
        PostCount,
        @rank := @rank + 1 AS Rank
    FROM
        TagCount, (SELECT @rank := 0) r
    ORDER BY
        PostCount DESC
)
SELECT
    tp.Rank AS TagRank,
    tt.Tag AS PopularTag,
    tt.PostCount AS TagPostCount,
    t.UserId,
    t.DisplayName AS Contributor,
    t.QuestionCount AS UserQuestionCount,
    t.OwnedQuestions,
    t.EditedQuestions
FROM
    TopParticipants t
JOIN
    TopTags tt ON tt.Rank <= 5 
ORDER BY
    tt.Rank, t.Rank;
