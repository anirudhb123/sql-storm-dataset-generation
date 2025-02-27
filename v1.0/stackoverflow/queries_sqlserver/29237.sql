
WITH TagCounts AS (
    SELECT
        value AS TagName,
        COUNT(*) AS QuestionCount
    FROM
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS Tag(value)
    WHERE
        PostTypeId = 1 
    GROUP BY
        value
),
TopTags AS (
    SELECT
        TagName,
        QuestionCount,
        ROW_NUMBER() OVER (ORDER BY QuestionCount DESC) AS TagRank
    FROM
        TagCounts
    WHERE
        QuestionCount > 5 
),
UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalQuestions,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        STRING_AGG(DISTINCT T.TagName, ', ') AS TagsUsed
    FROM
        Users U
    JOIN
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    CROSS APPLY STRING_SPLIT(SUBSTRING(P.Tags, 2, LEN(P.Tags) - 2), '><') AS T
    GROUP BY
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        TotalQuestions,
        TotalUpVotes,
        TotalDownVotes,
        TagsUsed,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM
        UserReputation
    WHERE
        TotalQuestions >= 5 
)
SELECT
    T.TagName,
    T.QuestionCount,
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalQuestions,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.TagsUsed,
    U.UserRank
FROM
    TopTags T
JOIN
    Posts P ON P.Tags LIKE '%' + T.TagName + '%'  
JOIN
    TopUsers U ON P.OwnerUserId = U.UserId
ORDER BY
    T.TagRank, U.UserRank;
