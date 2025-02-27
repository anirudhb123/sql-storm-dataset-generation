WITH TagPostCount AS (
    SELECT
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(Id) AS PostCount
    FROM
        Posts
    WHERE
        PostTypeId = 1 -- Only questions
    GROUP BY
        Tag
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
        p.PostTypeId = 1 -- Only questions
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
    Authors A ON T.Tag IN (
        SELECT unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><'))
        FROM Posts WHERE PostTypeId = 1 AND OwnerUserId IS NOT NULL
    )
WHERE 
    T.TagRank <= 10 -- Limit to top 10 tags
ORDER BY 
    T.PostCount DESC;
