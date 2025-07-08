
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD('year', -1, '2024-10-01'::DATE)
),
TopPostStats AS (
    SELECT 
        rp.OwnerName,
        COUNT(*) AS TotalPosts,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.Score) AS AvgScore,
        SUM(rp.ViewCount) AS TotalViews
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
    GROUP BY 
        rp.OwnerName
)
SELECT 
    t.OwnerName,
    t.TotalPosts,
    t.TotalScore,
    t.AvgScore,
    t.TotalViews,
    b.Name AS BadgeName,
    b.Class AS BadgeClass
FROM 
    TopPostStats t
LEFT JOIN 
    Badges b ON t.OwnerName = (SELECT u.DisplayName FROM Users u WHERE u.Id = b.UserId)
ORDER BY 
    t.TotalScore DESC, 
    t.OwnerName;
