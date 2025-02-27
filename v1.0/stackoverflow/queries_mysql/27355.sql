
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts P
    INNER JOIN (
        SELECT 
            1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
            SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
            SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        P.Tags IS NOT NULL
),
TagStats AS (
    SELECT 
        PT.Tag,
        COUNT(DISTINCT PT.PostId) AS PostCount,
        COUNT(DISTINCT U.Id) AS UserCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        PostTags PT
    JOIN 
        Posts P ON PT.PostId = P.Id
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        PT.Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        UserCount,
        QuestionCount,
        AnswerCount,
        @rank := @rank + 1 AS TagRank
    FROM 
        TagStats, (SELECT @rank := 0) r
    ORDER BY 
        PostCount DESC
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.Views,
    US.BadgeCount,
    TT.Tag,
    TT.PostCount AS TagPostCount,
    TT.UserCount AS TagUserCount,
    TT.QuestionCount AS TagQuestionCount,
    TT.AnswerCount AS TagAnswerCount
FROM 
    UserStats US
JOIN 
    TopTags TT ON TT.UserCount > 0
WHERE 
    US.Reputation > 1000
ORDER BY 
    TT.TagRank, US.Reputation DESC, US.Views DESC
LIMIT 10;
