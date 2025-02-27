
WITH TagCounts AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        value
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(ISNULL(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,  
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes  
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1  
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 100  
    GROUP BY 
        U.Id, U.DisplayName
),
PopularUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        TotalAnswers,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY QuestionCount DESC) AS UserRank
    FROM 
        UserStats
    WHERE 
        QuestionCount > 5  
)
SELECT 
    TT.TagName,
    TT.PostCount,
    PU.DisplayName,
    PU.QuestionCount,
    PU.TotalAnswers,
    PU.UpVotes,
    PU.DownVotes
FROM 
    TopTags TT
JOIN 
    PopularUsers PU ON TT.TagName LIKE '%' + PU.DisplayName + '%' 
WHERE 
    TT.TagRank <= 10  
ORDER BY 
    TT.PostCount DESC, PU.QuestionCount DESC;
