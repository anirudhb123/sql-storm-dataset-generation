WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    JOIN 
        Posts a ON a.AcceptedAnswerId = p.Id
    WHERE 
        p.PostTypeId = 2  -- Only answers
)
SELECT
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT q.Id) AS QuestionCount,
    SUM(COALESCE(q.Score, 0)) AS TotalQuestionScore,
    COUNT(DISTINCT a.Id) AS AnswerCount,
    SUM(COALESCE(a.Score, 0)) AS TotalAnswerScore,
    MAX(q.LastActivityDate) AS LastQuestionActivityDate,
    MAX(a.LastActivityDate) AS LastAnswerActivityDate,
    ARRAY_AGG(DISTINCT t.TagName) AS TagsUsed
FROM 
    Users u
LEFT JOIN 
    Posts q ON u.Id = q.OwnerUserId AND q.PostTypeId = 1  -- Questions
LEFT JOIN 
    Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2  -- Answers
LEFT JOIN 
    PostLinks pl ON pl.PostId = q.Id
LEFT JOIN 
    Posts rel ON rel.Id = pl.RelatedPostId
LEFT JOIN 
    Tags t ON rel.Tags ILIKE '%' || t.TagName || '%'  -- Find tags used in linked posts
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT q.Id) > 0 AND COUNT(DISTINCT a.Id) > 0
ORDER BY 
    TotalQuestionScore DESC, TotalAnswerScore DESC;

This SQL query performs the following:

1. **Common Table Expression (CTE):** A recursive CTE (`RecursivePostCTE`) to find all answers related to questions.
2. **Aggregations:** It aggregates data on users who have questions and answers, providing counts and sums of scores for both.
3. **JOINs:** Uses LEFT JOINs to get posts by the user, as well as linked posts and their tags.
4. **Filtering:** Filters to include only users with more than 1000 reputation and ensures that there are questions and answers associated with each user.
5. **Null Handling:** Uses `COALESCE` to avoid nulls when summing scores and applies filtering logic in the HAVING clause.
6. **String Operations:** Utilizes string operations to search for tags within related posts, ensuring a versatile lookup.
7. **Ordering:** Orders the results by total question scores and answers scores, ensuring that the highest contributors are listed first. 

This structured approach allows for a comprehensive view of the users' contributions based on posts and their engagement with the community.
