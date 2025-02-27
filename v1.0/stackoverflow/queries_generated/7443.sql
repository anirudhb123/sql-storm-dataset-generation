WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
), UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.ViewCount) AS TotalViews,
        AVG(rp.Score) AS AvgScorePerPost,
        COUNT(rp.PostId) AS QuestionCount,
        COUNT(rp.PostId) FILTER (WHERE rp.UserPostRank = 1) AS TopPostCount
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalScore,
    up.TotalViews,
    up.AvgScorePerPost,
    up.QuestionCount,
    up.TopPostCount,
    b.Name AS BadgeName,
    b.Class AS BadgeClass
FROM 
    UserPerformance up
LEFT JOIN 
    Badges b ON up.UserId = b.UserId 
WHERE 
    b.Date >= NOW() - INTERVAL '1 year' -- Only consider badges awarded in the last year
ORDER BY 
    up.TotalScore DESC, up.TotalViews DESC;
