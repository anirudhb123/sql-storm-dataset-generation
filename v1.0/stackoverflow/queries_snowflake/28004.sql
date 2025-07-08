
WITH TagCount AS (
    SELECT 
        TRIM(split_part(split_part(Tags, '><', number), '><', 1)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts,
        TABLE(GENERATOR(ROWCOUNT => 100)) AS seq(number) 
    WHERE 
        PostTypeId = 1  
        AND seq.number <= (LENGTH(Tags) - LENGTH(REPLACE(Tags, '><', '')))  + 1
    GROUP BY 
        TRIM(split_part(split_part(Tags, '><', number), '><', 1))
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCount
    WHERE 
        PostCount > 5 
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionsAsked,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionsAsked,
        UpVotesReceived,
        DownVotesReceived,
        ROW_NUMBER() OVER (ORDER BY UpVotesReceived DESC) AS Rank
    FROM 
        UserEngagement
    WHERE 
        QuestionsAsked > 0
)
SELECT 
    TT.TagName,
    TT.PostCount AS TotalQuestions,
    TU.DisplayName AS TopUser,
    TU.QuestionsAsked,
    TU.UpVotesReceived,
    TU.DownVotesReceived
FROM 
    TopTags TT
LEFT JOIN 
    TopUsers TU ON TU.Rank = 1 
ORDER BY 
    TT.PostCount DESC, TU.UpVotesReceived DESC;
