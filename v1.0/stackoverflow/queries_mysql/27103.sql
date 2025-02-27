
WITH TagFrequency AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    ON 
        CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName
),
MostActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS QuestionCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        U.Id, U.DisplayName
),
TopTags AS (
    SELECT 
        TF.TagName,
        TF.PostCount,
        @rownum := @rownum + 1 AS TagRank
    FROM 
        TagFrequency TF, (SELECT @rownum := 0) r
    ORDER BY 
        TF.PostCount DESC
),
TopUsers AS (
    SELECT 
        MA.UserId,
        MA.DisplayName,
        MA.QuestionCount,
        MA.UpVoteCount,
        MA.DownVoteCount,
        MA.AcceptedAnswerCount,
        @rownum2 := @rownum2 + 1 AS UserRank
    FROM 
        MostActiveUsers MA, (SELECT @rownum2 := 0) r
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.QuestionCount AS TotalQuestions,
    TU.UpVoteCount AS TotalUpVotes,
    TU.DownVoteCount AS TotalDownVotes,
    TU.AcceptedAnswerCount AS TotalAcceptedAnswers,
    TT.TagName AS TopTag,
    TT.PostCount AS TagPostCount
FROM 
    TopUsers TU
JOIN 
    TopTags TT ON TT.TagRank <= 5  
WHERE 
    TU.UserRank <= 10  
ORDER BY 
    TU.QuestionCount DESC, 
    TT.PostCount DESC;
