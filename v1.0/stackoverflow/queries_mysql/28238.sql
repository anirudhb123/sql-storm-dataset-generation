
WITH ProcessedTags AS (
    SELECT 
        P.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) AS TagName,
        P.Title,
        P.Body,
        P.CreationDate
    FROM 
        Posts P
    JOIN (
        SELECT 
            1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
            SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
            SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL 
            SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL 
            SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
        ) numbers ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        P.PostTypeId = 1  
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS TagUsageCount,
        AVG(U.QuestionCount) AS AvgQuestionsPerUser,
        SUM(U.UpVoteCount) AS TotalUpVotes
    FROM 
        ProcessedTags T
    JOIN Posts P ON T.PostId = P.Id
    JOIN UserEngagement U ON P.OwnerUserId = U.UserId
    GROUP BY 
        T.TagName
),
EngagingTags AS (
    SELECT 
        TagName,
        TagUsageCount,
        AvgQuestionsPerUser,
        TotalUpVotes,
        @rank := @rank + 1 AS PopularityRank
    FROM 
        TagStatistics, (SELECT @rank := 0) r
    WHERE 
        TagUsageCount > 10  
    ORDER BY 
        TotalUpVotes DESC
)
SELECT 
    TagName,
    TagUsageCount,
    AvgQuestionsPerUser,
    TotalUpVotes,
    PopularityRank
FROM 
    EngagingTags
WHERE 
    PopularityRank <= 10  
ORDER BY 
    PopularityRank;
