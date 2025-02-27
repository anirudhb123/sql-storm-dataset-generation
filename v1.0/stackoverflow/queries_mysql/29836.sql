
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    INNER JOIN (
        SELECT 
            @row := @row + 1 AS n 
        FROM 
            (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
             UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers,
            (SELECT @row := 0) r
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        Tag
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesReceived,
        COALESCE(SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesReceived,
        COALESCE(SUM(CASE WHEN V.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentsCount,
        COUNT(DISTINCT P.Id) AS QuestionsAsked,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswersProvided,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT
        Tag,
        PostCount,
        @row := @row + 1 AS Rank
    FROM 
        TagCounts, (SELECT @row := 0) r
    WHERE 
        PostCount > 5  
    ORDER BY 
        PostCount DESC
),
UserEngagement AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.QuestionsAsked,
        UA.AnswersProvided,
        UA.CommentsCount,
        UA.UpVotesReceived,
        UA.DownVotesReceived,
        UA.TotalViews,
        PT.Tag,
        PCT.PostCount
    FROM 
        UserActivity UA
    JOIN 
        Posts P ON UA.UserId = P.OwnerUserId
    JOIN 
        PopularTags PT ON FIND_IN_SET(PT.Tag, REPLACE(SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2), '><', ',')) > 0
    JOIN 
        TagCounts PCT ON PT.Tag = PCT.Tag
)
SELECT 
    UE.DisplayName,
    UE.QuestionsAsked,
    UE.AnswersProvided,
    UE.CommentsCount,
    SUM(UE.UpVotesReceived - UE.DownVotesReceived) AS NetVotes,
    SUM(UE.TotalViews) AS TotalViews,
    GROUP_CONCAT(DISTINCT UE.Tag SEPARATOR ', ') AS RelatedTags,
    COUNT(DISTINCT UE.Tag) AS UniqueTagsEngaged
FROM 
    UserEngagement UE
GROUP BY 
    UE.DisplayName, UE.QuestionsAsked, UE.AnswersProvided, UE.CommentsCount
ORDER BY 
    TotalViews DESC
LIMIT 10;
