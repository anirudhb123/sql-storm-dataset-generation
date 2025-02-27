WITH RecursivePostHierarchy AS (
    -- Base case: Select all questions as the starting point of the hierarchy
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions

    UNION ALL

    -- Recursive case: Join to find answers (children posts)
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
)

-- Main query: Selecting user and post details from the hierarchy created
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    COUNT(DISTINCT p2.Id) AS AnswerCount,
    AVG(COALESCE(p2.Score, 0)) AS AverageAnswerScore,
    MAX(p1.CreationDate) AS LatestQuestionDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags
FROM 
    Users u
LEFT JOIN 
    Posts p1 ON p1.OwnerUserId = u.Id AND p1.PostTypeId = 1  -- Questions
LEFT JOIN 
    RecursivePostHierarchy p2 ON p2.OwnerUserId = u.Id -- Answers
LEFT JOIN 
    LATERAL (
        SELECT 
            UNNEST(string_to_array(p1.Tags, ',')) AS TagName
    ) t ON TRUE
GROUP BY 
    u.Id
ORDER BY 
    Reputation DESC
LIMIT 10
OFFSET 0;

### Query Explanation:
1. **Recursive Common Table Expression (CTE)**:
   - The CTE `RecursivePostHierarchy` builds a hierarchy of posts, starting from questions (`PostTypeId = 1`) and recursively joining to find related answers (children posts).

2. **Main Query**:
   - The main query retrieves user details and aggregates data.
   - It calculates the total number of distinct answers per user and averages the scores of these answers.
   - It also retrieves the latest question date and concatenates the distinct tags related to the questions.

3. **LEFT JOIN with LATERAL**:
   - This allows extracting and aggregating tags associated with questions.

4. **Group and Order**:
   - The results are grouped by user and ordered by reputation to provide insights into the top users, displaying their engagement through questions and answers.

5. **Pagination**:
   - The query uses `LIMIT` and `OFFSET` for pagination purposes.
