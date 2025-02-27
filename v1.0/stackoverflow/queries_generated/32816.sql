WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        CAST(0 AS INT) AS Level,
        p.ParentId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.CreationDate,
        p2.OwnerUserId,
        Level + 1,
        p2.ParentId
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy rph ON p2.ParentId = rph.Id
)

SELECT 
    u.DisplayName AS UserName,
    COUNT(DISTINCT q.Id) AS TotalQuestions,
    COUNT(DISTINCT a.Id) AS TotalAnswers,
    SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
    SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
    AVG(Score) AS AverageScore,
    STRING_AGG(DISTINCT CONCAT('[', t.TagName, ']'), ', ') AS Tags
FROM 
    Users u
LEFT JOIN 
    Posts q ON u.Id = q.OwnerUserId AND q.PostTypeId = 1 -- Questions
LEFT JOIN 
    Posts a ON a.AcceptedAnswerId = q.Id -- Answers
LEFT JOIN 
    Votes v ON v.PostId IN (SELECT Id FROM RecursivePostHierarchy WHERE Level = 0)
LEFT JOIN 
    LATERAL (SELECT 
                  t.TagName 
              FROM 
                  Tags t 
              WHERE 
                  t.ExcerptPostId = q.Id) t ON TRUE
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT q.Id) > 0
ORDER BY 
    TotalQuestions DESC,
    TotalUpVotes DESC;

WITH PostScores AS (
    SELECT 
        p.Id,
        CASE 
            WHEN p.Score >= 100 THEN 'High'
            WHEN p.Score BETWEEN 50 AND 99 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory
    FROM 
        Posts p
)

SELECT 
    ps.ScoreCategory,
    COUNT(*) AS CountOfPosts,
    AVG(COALESCE(v.BountyAmount, 0)) AS AverageBountyAmount
FROM 
    PostScores ps
LEFT JOIN 
    Votes v ON ps.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart or BountyClose
GROUP BY 
    ps.ScoreCategory
ORDER BY 
    ScoreCategory;
