WITH TagCount AS (
    SELECT
        LOWER(TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')))) AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    WHERE
        PostTypeId = 1  -- Only consider questions
    GROUP BY
        LOWER(TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))))
),

UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS UpvotedQuestions
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 -- Questions only
    GROUP BY
        U.Id
),

TopTags AS (
    SELECT
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM
        TagCount
    WHERE
        PostCount > 5  -- Display tags with more than 5 questions
),

UserActivity AS (
    SELECT
        UA.UserId,
        UA.DisplayName,
        MAX(P.CreationDate) AS LastActiveDate,
        AVG(U.Reputation) AS AverageReputation
    FROM
        UserReputation UA
    JOIN
        Posts P ON UA.UserId = P.OwnerUserId
    GROUP BY
        UA.UserId, UA.DisplayName
)

SELECT
    U.DisplayName AS Contributor,
    T.TagName,
    T.PostCount,
    UA.LastActiveDate,
    UA.AverageReputation
FROM
    TopTags T
JOIN
    UserReputation UR ON T.TagName = ANY(SPLIT_PARTS(UR.Tags, '>')) -- Match tags with users having questions
JOIN
    UserActivity UA ON UR.UserId = UA.UserId
WHERE
    T.TagRank <= 10  -- Limit to top 10 tags
ORDER BY
    T.PostCount DESC, UA.AverageReputation DESC;
