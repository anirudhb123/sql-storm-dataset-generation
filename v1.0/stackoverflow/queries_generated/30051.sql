WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.AcceptedAnswerId,
        rp.Level + 1  -- Increase level for Depth
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE rp ON p.ParentId = rp.PostId
)

SELECT 
    u.DisplayName AS UserName,
    COUNT(DISTINCT rp.PostId) AS TotalQuestions,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers,
    AVG(DATEDIFF(HOUR, rp.CreationDate, COALESCE(pa.CreationDate, GETDATE()))) AS AvgAnswerTime,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    MAX(p.Score) AS MaxScore,
    MIN(p.CreationDate) AS FirstPostDate,
    MAX(p.LastActivityDate) AS LastActiveDate,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPostCount
FROM 
    RecursivePostCTE rp
LEFT JOIN 
    Posts p ON p.Id = rp.AcceptedAnswerId
LEFT JOIN 
    Users u ON u.Id = rp.OwnerUserId
LEFT JOIN 
    Tags t ON t.Id IN (
        SELECT 
            unnest(string_to_array(rp.Tags, '<>'))::int
    )
LEFT JOIN 
    Badges b ON b.UserId = u.Id
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT rp.PostId) > 10
ORDER BY 
    TotalQuestions DESC, UserName
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;

This query performs the following operations:
1. A recursive CTE (`RecursivePostCTE`) to traverse the question and its nested answers.
2. Aggregates user statistics based on the posts they own, including the total number of questions, accepted answers, average time to answer, and tags used.
3. A variety of counting and summing transformations are used, along with some conditional counting and string aggregation.
4. It uses NULL checks, COALESCE, and string manipulation for tags.
5. Implements pagination with OFFSET and FETCH, returning a specific subset of data.
