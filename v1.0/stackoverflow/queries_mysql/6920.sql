
WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        (U.UpVotes - U.DownVotes) AS NetVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.UpVotes, U.DownVotes
),  
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        NetVotes,
        PostCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY NetVotes DESC) AS NetVotesRank
    FROM 
        UserScore
),
QuestionTags AS (
    SELECT 
        P.Id AS QuestionId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts P
    INNER JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
         SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        P.PostTypeId = 1
),
TagPopularity AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        QuestionTags
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.NetVotes,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TP.Tag,
    TP.TagCount
FROM 
    TopUsers TU
JOIN 
    TagPopularity TP ON TU.QuestionCount > 0
ORDER BY 
    TU.ReputationRank, TU.NetVotesRank;
