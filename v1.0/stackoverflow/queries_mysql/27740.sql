
WITH TagPostCount AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(Id) AS PostCount
    FROM
        Posts
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
        UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE
        PostTypeId = 1 
    GROUP BY
        Tag
),
TopTags AS (
    SELECT
        Tag,
        PostCount,
        @row_number := @row_number + 1 AS TagRank
    FROM
        TagPostCount,
        (SELECT @row_number := 0) AS rn
    ORDER BY PostCount DESC
),
Authors AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveAnsweredCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM
        Users u
    JOIN
        Posts p ON u.Id = p.OwnerUserId
    WHERE
        p.PostTypeId = 1 
    GROUP BY
        u.Id, u.DisplayName
)
SELECT 
    T.Tag,
    T.PostCount,
    A.DisplayName,
    A.QuestionCount,
    A.PositiveAnsweredCount,
    A.AcceptedAnswers
FROM 
    TopTags T
JOIN 
    Authors A ON A.UserId IN (
        SELECT p.OwnerUserId
        FROM Posts p 
        WHERE p.PostTypeId = 1 AND p.OwnerUserId IS NOT NULL
        AND EXISTS (
            SELECT 1 
            FROM (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag
                  FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 
                        UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 
                        UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
                        UNION ALL SELECT 10) numbers
                  WHERE CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1) AS TagsTable
            WHERE TagsTable.Tag = T.Tag
        )
    )
WHERE 
    T.TagRank <= 10 
ORDER BY 
    T.PostCount DESC;
