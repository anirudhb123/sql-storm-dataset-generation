WITH RecursivePostHierarchy AS (
    -- CTE to get the hierarchy of questions and their answers
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.OwnerUserId,
        ph.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        Posts q ON a.ParentId = q.Id
    INNER JOIN 
        RecursivePostHierarchy ph ON q.Id = ph.PostId
)

SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS Owner,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
    COUNT(DISTINCT v.UserId) AS UniqueVoters,
    AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS AverageVoteScore,
    COUNT(DISTINCT CASE WHEN b.Id IS NOT NULL THEN b.Id END) AS BadgeCount,
    ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(DISTINCT c.Id) DESC) AS RankByComments,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    RecursivePostHierarchy rh
INNER JOIN 
    Posts p ON rh.PostId = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON b.UserId = p.OwnerUserId
LEFT JOIN 
    Posts t ON p.Tags LIKE '%' || t.TagName || '%'
GROUP BY 
    p.Id, p.Title, u.DisplayName
HAVING 
    COUNT(DISTINCT c.Id) > 0
ORDER BY 
    TotalBountyAmount DESC, RankByComments;

In this SQL query:

1. A recursive CTE named `RecursivePostHierarchy` organizes posts in a hierarchy based on questions and their answers.
2. The main SELECT statement aggregates metrics about each question, including comment counts, total bounty amounts, unique voters, average vote scores, and badge counts.
3. The `STRING_AGG` function is utilized to concatenate tag names associated with each question.
4. The `HAVING` clause filters out questions with zero comments, ensuring the results focus on actively discussed questions.
5. Finally, results are ordered by total bounty amount and rank by comments.
