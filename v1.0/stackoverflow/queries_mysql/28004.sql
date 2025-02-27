
WITH TagCount AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
    (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
        UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1))
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        @rownum := @rownum + 1 AS Rank
    FROM 
        TagCount, (SELECT @rownum := 0) r
    WHERE 
        PostCount > 5 
    ORDER BY 
        PostCount DESC
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
        @rownum2 := @rownum2 + 1 AS Rank
    FROM 
        UserEngagement, (SELECT @rownum2 := 0) r
    WHERE 
        QuestionsAsked > 0
    ORDER BY 
        UpVotesReceived DESC
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
