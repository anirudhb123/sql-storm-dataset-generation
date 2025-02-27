WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),

TopAnswers AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS AnswerRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 2 -- Answers
)

SELECT 
    u.UserId,
    u.DisplayName,
    COALESCE(us.TotalPosts, 0) AS TotalPosts,
    COALESCE(us.TotalViews, 0) AS TotalViews,
    COALESCE(us.TotalScore, 0) AS TotalScore,
    tp.PostId AS TopPostId,
    tp.Title AS TopPostTitle,
    tp.Score AS TopPostScore,
    tp.AnswerCount AS TopPostAnswerCount
FROM 
    Users u
LEFT JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    TopAnswers tp ON u.Id = tp.OwnerUserId AND tp.AnswerRank = 1
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.DisplayName;

SELECT 
    DISTINCT p.Tags
FROM 
    Posts p
WHERE 
    p.LastActivityDate >= NOW() - INTERVAL '30 days'
EXCEPT
SELECT 
    DISTINCT t.TagName
FROM 
    Tags t
JOIN 
    Posts p ON t.Id = p.ExcerptPostId
WHERE 
    t.IsModeratorOnly = 1;
