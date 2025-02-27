
WITH TagCounts AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS QuestionCount
    FROM
        Posts
    JOIN (
        SELECT 
            1 AS n UNION ALL SELECT 
            2 UNION ALL SELECT 
            3 UNION ALL SELECT 
            4 UNION ALL SELECT 
            5 UNION ALL SELECT 
            6 UNION ALL SELECT 
            7 UNION ALL SELECT 
            8 UNION ALL SELECT 
            9 UNION ALL SELECT 
            10
    ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE
        PostTypeId = 1 
    GROUP BY
        TagName
),
TopTags AS (
    SELECT
        TagName,
        QuestionCount,
        @rownum := @rownum + 1 AS TagRank
    FROM
        TagCounts, (SELECT @rownum := 0) r
    WHERE
        QuestionCount > 5 
    ORDER BY QuestionCount DESC
),
UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalQuestions,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        GROUP_CONCAT(DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', n.n), '><', -1) ORDER BY n.n ASC SEPARATOR ', ') AS TagsUsed
    FROM
        Users U
    JOIN
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    JOIN (
        SELECT 
            1 AS n UNION ALL SELECT 
            2 UNION ALL SELECT 
            3 UNION ALL SELECT 
            4 UNION ALL SELECT 
            5 UNION ALL SELECT 
            6 UNION ALL SELECT 
            7 UNION ALL SELECT 
            8 UNION ALL SELECT 
            9 UNION ALL SELECT 
            10
    ) n ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= n.n - 1
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
        @user_rank := @user_rank + 1 AS UserRank
    FROM
        UserReputation, (SELECT @user_rank := 0) r
    WHERE
        TotalQuestions >= 5 
    ORDER BY Reputation DESC
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
    Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')  
JOIN
    TopUsers U ON P.OwnerUserId = U.UserId
ORDER BY
    T.TagRank, U.UserRank;
