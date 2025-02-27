WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2020-01-01' 
        AND p.OwnerUserId IS NOT NULL
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        MAX(p.Score) AS MaxScore,
        MIN(p.Score) AS MinScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, ' | ') AS Comments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    u.DisplayName,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.AvgScore,
    us.MaxScore,
    us.MinScore,
    pp.PostRank,
    pp.Title,
    pc.CommentCount,
    COALESCE(pc.Comments, 'No comments') AS LatestComments
FROM 
    UserStatistics us
JOIN 
    Users u ON u.Id = us.UserId
LEFT JOIN 
    RankedPosts pp ON pp.OwnerUserId = u.Id AND pp.PostRank = 1
LEFT JOIN 
    PostComments pc ON pc.PostId = pp.PostId
WHERE 
    us.TotalPosts > 5
    AND (us.MaxScore > 10 OR us.AvgScore > 5)
    AND EXISTS (
        SELECT 1 
        FROM Badges b 
        WHERE b.UserId = u.Id AND b.Class = 1
    )
ORDER BY 
    us.TotalPosts DESC, u.Reputation DESC;

-- Additional Statistics
SELECT
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(COALESCE(p.Score, 0)) AS AvgScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
HAVING 
    COUNT(p.Id) > 10
ORDER BY 
    AvgScore DESC;

-- User badges with unusual predicates
SELECT 
    u.DisplayName,
    b.Name,
    b.Class,
    b.Date
FROM 
    Users u
JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    b.Date > CURRENT_DATE - INTERVAL '1 year'
    AND b.Class IN (1, 2, 3)
    AND b.TagBased IS FALSE
ORDER BY 
    u.Reputation DESC, b.Class ASC;

-- CTE for analyzing users with diminishing returns on score
WITH UserScoreTrend AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS ScoreRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalScore,
    CASE 
        WHEN u.TotalScore BETWEEN 0 AND 100 THEN 'Newbie'
        WHEN u.TotalScore BETWEEN 101 AND 500 THEN 'Intermediate'
        ELSE 'Expert'
    END AS UserLevel
FROM
    UserScoreTrend u
WHERE 
    u.TotalScore IS NOT NULL
    AND u.ScoreRank <= 100
ORDER BY 
    u.TotalScore DESC;
