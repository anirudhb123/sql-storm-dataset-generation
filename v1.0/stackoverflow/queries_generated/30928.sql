WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS QuestionsPosted,
    COUNT(DISTINCT a.Id) AS AnswersPosted,
    SUM(COALESCE(v.Score, 0)) AS TotalVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    CASE 
        WHEN AVG(COALESCE(p.Score, 0)) > 10 THEN 'High' 
        WHEN AVG(COALESCE(p.Score, 0)) BETWEEN 1 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS AveragePostScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  -- Questions
LEFT JOIN 
    Posts a ON a.AcceptedAnswerId = p.Id  -- Answers to Questions
LEFT JOIN 
    Votes v ON v.PostId = p.Id  -- Votes on Questions
LEFT JOIN 
    LATERAL (
        SELECT 
            DISTINCT unnest(string_to_array(p.Tags, '><')) AS TagName
    ) t ON TRUE  -- Extracting tags from Questions
LEFT JOIN 
    RecursivePostHierarchy r ON r.PostId = p.Id  -- Joining with recursive CTE
WHERE 
    u.Reputation > 1000  -- Filtering users with significant reputation
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT p.Id) > 5  -- User must have posted more than 5 questions
ORDER BY 
    TotalVotes DESC, AveragePostScore ASC;
This query includes:

1. A recursive CTE to build a hierarchy of posts.
2. Multiple joins to gather information from several tables, including `Posts`, `Votes`, and a lateral join to extract tags.
3. Aggregate functions to count questions and answers and sum up the total votes.
4. Grouping and having clauses to filter results based on user reputation and the number of questions posted.
5. Conditional logic to categorize average post score.
6. Use of `STRING_AGG` to concatenate distinct tags used by the user.
