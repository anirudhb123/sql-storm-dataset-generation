WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Starting from Questions
    UNION ALL
    SELECT 
        p2.Id,
        p2.Title,
        p2.OwnerUserId,
        p2.CreationDate,
        p2.Score,
        p2.ParentId,
        r.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostCTE r ON p2.ParentId = r.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName AS UserName,
    COUNT(DISTINCT r.PostId) AS TotalQuestions,
    COUNT(DISTINCT p.Id) AS TotalAnswers,
    SUM(p.Score) AS TotalScore,
    COALESCE(MAX(b.Class), 0) AS HighestBadgeClass,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    ROUND(AVG(DATE_PART('day', CURRENT_TIMESTAMP - p.CreationDate)), 2) AS AvgDaysToResponse
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2 -- Answers
LEFT JOIN 
    RecursivePostCTE r ON p.ParentId = r.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Votes v ON u.Id = v.UserId AND v.PostId IN (SELECT PostId FROM RecursivePostCTE)
LEFT JOIN 
    UNNEST(STRING_TO_ARRAY((SELECT STRING_AGG(t.TagName, ',') FROM Tags t WHERE t.Id = ANY(STRING_TO_ARRAY(COALESCE(r.Tags, '[]'), ','))), ',')) AS t
WHERE 
    u.Reputation > 100
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalScore DESC, UserName ASC;

This query performs the following tasks:

1. **Recursive CTE**: It creates a recursive Common Table Expression (`RecursivePostCTE`) to gather parent-child relationships for questions and their answers.

2. **Aggregating User Data**: It joins the `Users`, `Posts`, `Badges`, and `Votes` tables to summarize users’ contributions based on their questions and answers while filtering users with a reputation over 100.

3. **Calculating Metrics**:
   - Counts total questions and answers.
   - Sums the scores of all their answers.
   - Retrieves the highest class of any badge they possess.
   - Counts total votes they received for their answers.

4. **Tag Aggregation**: It utilizes string functions to gather all tags associated with the user's posts.

5. **Average Days to Response**: It calculates the average time taken to get a response in days for all the answers associated with the questions.

6. **Final Output**: Orders the results by total score descending and by user name ascending.
