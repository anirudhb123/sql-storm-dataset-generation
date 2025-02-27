WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1
)
SELECT 
    r.OwnerDisplayName,
    COUNT(r.Id) AS TotalQuestions,
    AVG(r.Score) AS AvgScore,
    SUM(r.ViewCount) AS TotalViews,
    SUM(r.AnswerCount) AS TotalAnswers,
    SUM(r.CommentCount) AS TotalComments
FROM 
    RankedPosts r
WHERE 
    r.PostRank <= 3
GROUP BY 
    r.OwnerDisplayName
ORDER BY 
    TotalQuestions DESC, AvgScore DESC
LIMIT 10;

WITH BadgesCount AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    b.BadgeCount
FROM 
    Users u
LEFT JOIN 
    BadgesCount b ON u.Id = b.UserId
WHERE 
    u.Reputation >= 1000
ORDER BY 
    u.Reputation DESC
LIMIT 10;
