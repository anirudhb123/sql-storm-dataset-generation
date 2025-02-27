WITH TagStats AS (
    SELECT
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS TotalViews
    FROM
        Tags T
    LEFT JOIN
        Posts P ON T.Id = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')::int[])
    GROUP BY
        T.TagName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViews,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank,
        RANK() OVER (ORDER BY QuestionCount DESC) AS QuestionRank
    FROM
        TagStats
),
TagDetails AS (
    SELECT
        TT.TagName,
        TT.PostCount,
        TT.QuestionCount,
        TT.AnswerCount,
        TT.TotalViews,
        (SELECT ARRAY_AGG(DISTINCT U.DisplayName ORDER BY U.Reputation DESC)
         FROM Users U
         JOIN Posts P ON U.Id = P.OwnerUserId
         WHERE P.Tags LIKE '%' || TT.TagName || '%'
         LIMIT 5) AS TopUsers, -- Get top users for each tag
        CASE
            WHEN TT.ViewRank <= 5 THEN 'High Activity'
            WHEN TT.ViewRank <= 10 THEN 'Medium Activity'
            ELSE 'Low Activity'
        END AS ActivityLevel
    FROM
        TopTags TT
)
SELECT
    TagName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViews,
    TopUsers,
    ActivityLevel
FROM
    TagDetails
ORDER BY
    TotalViews DESC, QuestionCount DESC;
