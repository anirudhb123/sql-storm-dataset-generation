WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '> %') OR p.Tags LIKE CONCAT('<', t.TagName, '> %') 
        OR p.Tags LIKE CONCAT('% <', t.TagName, '>') OR p.Tags LIKE CONCAT('%<', t.TagName, '>') 
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
MostActiveUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id
    ORDER BY 
        TotalPosts DESC
    LIMIT 5
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AverageReputation,
    mau.DisplayName AS MostActiveUser,
    mau.Reputation AS ActiveUserReputation,
    mau.TotalPosts
FROM 
    TagStats ts
LEFT JOIN 
    MostActiveUsers mau ON ts.QuestionCount > 0
ORDER BY 
    ts.PostCount DESC, ts.AverageReputation DESC;

This SQL query performs the following:

1. **TagStats CTE**: Aggregates statistics for each tag, counting how many posts are associated with each tag, separating counts for questions and answers, and calculating the average reputation of users who posted.

2. **MostActiveUsers CTE**: Identifies the top 5 users based on the number of posts they've made.

3. **Final Select Statement**: Combines the data from both CTEs, showing for each tag the total number of posts, the question and answer counts, along with the average user reputation. Additionally, it lists the most active user who has contributed questions under each tag alongside their reputation and the total posts they've made.

4. **Ordering**: Finally, it orders the results by post count and average reputation, allowing for a clear view of the most active tags and their contributors.
