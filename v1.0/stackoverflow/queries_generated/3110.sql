WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        ROW_NUMBER() OVER (ORDER BY COUNT(p.Id) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- BountyStart and BountyClose
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalBounty
    FROM 
        UserPostStats
    WHERE 
        Rank <= 10
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.TotalBounty,
    COALESCE(c.CommentCount, 0) AS TotalComments,
    COALESCE(pac.AcceptedAnswerCount, 0) AS AcceptedAnswers
FROM 
    TopUsers tu
LEFT JOIN 
    (SELECT 
         OwnerUserId,
         COUNT(Id) AS CommentCount 
     FROM 
         Comments 
     GROUP BY 
         OwnerUserId) c ON tu.UserId = c.OwnerUserId
LEFT JOIN 
    (SELECT 
         OwnerUserId,
         COUNT(*) AS AcceptedAnswerCount 
     FROM 
         Posts 
     WHERE 
         AcceptedAnswerId IS NOT NULL 
     GROUP BY 
         OwnerUserId) pac ON tu.UserId = pac.OwnerUserId
ORDER BY 
    tu.TotalPosts DESC;

-- Additional section for performance benchmarking
EXPLAIN ANALYZE
SELECT 
    p.Id AS PostId,
    p.Title,
    ph.CreationDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, ',') AS tags_array 
ON 
    TRUE
LEFT JOIN 
    Tags t ON t.TagName = TRIM(tags_array)
WHERE 
    p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
GROUP BY 
    p.Id, p.Title, ph.CreationDate
HAVING 
    COUNT(DISTINCT t.Id) > 1
ORDER BY 
    ph.CreationDate DESC
LIMIT 50;
