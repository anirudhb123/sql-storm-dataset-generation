-- This query benchmarks string processing by counting the number of posts with similar tags,
-- extracting relevant user details, and performance metrics on string operations
WITH TagCounts AS (
    SELECT 
        TRIM(unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only consider Questions
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 1  -- Only keep tags that appear in more than one question
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionsAsked,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveVotesReceived,
        AVG(EXTRACT(EPOCH FROM (NOW() - u.CreationDate)) / 86400) AS AverageDaysSinceAccountCreation
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1  -- Focus only on Questions
    GROUP BY 
        u.Id, u.DisplayName
),
TagUserActivities AS (
    SELECT 
        t.TagName,
        u.UserId,
        u.DisplayName,
        ua.QuestionsAsked,
        ua.PositiveVotesReceived,
        ua.AverageDaysSinceAccountCreation
    FROM 
        TagCounts t
    JOIN 
        Posts p ON t.TagName = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))
    JOIN 
        UserActivity ua ON p.OwnerUserId = ua.UserId
)
SELECT 
    t.TagName,
    COUNT(DISTINCT t.UserId) AS UniqueUsers,
    AVG(QuestionsAsked) AS AvgQuestionsAsked,
    AVG(PositiveVotesReceived) AS AvgPositiveVotes,
    AVG(AverageDaysSinceAccountCreation) AS AvgDaysSinceCreation
FROM 
    TagUserActivities t
GROUP BY 
    t.TagName
ORDER BY 
    UniqueUsers DESC, AvgPositiveVotes DESC;
