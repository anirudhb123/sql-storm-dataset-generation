
WITH TagPostCount AS (
    SELECT
        value AS Tag,
        COUNT(Id) AS PostCount
    FROM
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS Tag
    WHERE
        PostTypeId = 1 
    GROUP BY
        value
),
TopTags AS (
    SELECT
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM
        TagPostCount
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
            FROM STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS Tag
            WHERE Tag.value = T.Tag
        )
    )
WHERE 
    T.TagRank <= 10 
ORDER BY 
    T.PostCount DESC;
