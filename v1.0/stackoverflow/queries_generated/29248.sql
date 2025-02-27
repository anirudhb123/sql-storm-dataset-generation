WITH ProcessedTags AS (
    SELECT 
        Id AS TagId,
        TagName,
        Count,
        EXTRACT(YEAR FROM MAX(CreationDate)) AS MaxCreationYear,
        COUNT(DISTINCT PostId) AS AssociatedPostCount
    FROM 
        Tags 
    JOIN 
        Posts ON Tags.Id = Posts.Tags::text::int[]
    GROUP BY 
        Id
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        U.Reputation
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
TagPerformance AS (
    SELECT 
        PT.TagId,
        PT.TagName,
        SUM(UT.TotalPosts) AS TotalPostsContributed,
        AVG(UT.Reputation) AS AvgReputation,
        SUM(CASE WHEN UT.QuestionCount > 0 THEN 1 ELSE 0 END) AS ActiveQuestionContributors
    FROM 
        ProcessedTags PT
    JOIN 
        Posts POS ON POSITION(CONCAT('<', PT.TagName, '>') IN POS.Tags) > 0
    JOIN 
        UserStatistics UT ON POS.OwnerUserId = UT.UserId
    GROUP BY 
        PT.TagId, PT.TagName
)
SELECT 
    TP.TagId,
    TP.TagName,
    TP.TotalPostsContributed,
    TP.AvgReputation,
    TP.ActiveQuestionContributors,
    T.Count AS TotalTagCount,
    U.Reputation AS MostActiveUserReputation,
    U.DisplayName AS MostActiveUserName
FROM 
    TagPerformance TP
JOIN 
    Tags T ON TP.TagId = T.Id
JOIN 
    (SELECT 
         PT.TagId,
         U.Id AS UserId,
         U.DisplayName,
         U.Reputation,
         ROW_NUMBER() OVER (PARTITION BY PT.TagId ORDER BY U.Reputation DESC) AS RN
     FROM 
         Tags PT
     JOIN 
         Posts POS ON POSITION(CONCAT('<', PT.TagName, '>') IN POS.Tags) > 0
     JOIN 
         Users U ON POS.OwnerUserId = U.Id
     ) U ON TP.TagId = U.TagId AND U.RN = 1
ORDER BY 
    TP.TotalPostsContributed DESC, 
    TP.AvgReputation DESC;
