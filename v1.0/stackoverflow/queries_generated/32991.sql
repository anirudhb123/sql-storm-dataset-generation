WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level,
        p.CreationDate,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        Level + 1,
        p.CreationDate,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, 0)
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
)

SELECT 
    u.DisplayName AS UserName,
    COUNT(DISTINCT p.Id) AS QuestionCount,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswersCount,
    AVG(DATEDIFF(MINUTE, p.CreationDate, GETDATE())) AS AvgTimeToStatusInMinutes
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  -- Questions
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    RecursivePostHierarchy rph ON p.Id = rph.PostId
WHERE 
    u.Reputation > 1000  -- Only users with reputation over 1000
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 0
ORDER BY 
    TotalViews DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

### Explanation of the Query Constructs:
1. **Recursive CTE**: The CTE `RecursivePostHierarchy` finds all child posts (answers) associated with a question, allowing hierarchical queries on posts.

2. **Selection of User Statistics**: The main query computes various statistics about users such as the count of their questions, the total views those questions have garnered, and the number of accepted answers.

3. **Conditional Aggregation**: It uses `SUM` with `CASE` and `COALESCE` to combine results in a meaningful way while avoiding nulls.

4. **AVG Function with DateDiff**: Average time is calculated based on the difference between the question creation date and the current timestamp.

5. **Filtering by Reputation**: The query filters to only include users with a certain level of reputation, making it a targeted analysis of active contributors.

6. **Ordering and Pagination**: The results are ordered based on total views and paginated to return only the top ten users.

This query serves as a comprehensive example of how to analyze user performance in the context of the Stack Overflow schema while leveraging complex SQL features for a richer dataset.
