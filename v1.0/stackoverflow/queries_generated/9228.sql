WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score > 0 -- Only questions with score
),
PostStatistics AS (
    SELECT 
        rp.Owner,
        COUNT(rp.PostId) AS TotalQuestions,
        AVG(rp.ViewCount) AS AvgViews,
        SUM(rp.Score) AS TotalScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 -- Top 5 questions per user
    GROUP BY 
        rp.Owner
)
SELECT 
    ps.Owner,
    ps.TotalQuestions,
    ps.AvgViews,
    ps.TotalScore,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = (SELECT Id FROM Users WHERE DisplayName = ps.Owner)) AS BadgeCount
FROM 
    PostStatistics ps
ORDER BY 
    ps.TotalScore DESC, 
    ps.AvgViews DESC
LIMIT 
    10;
