WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND  -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostStats AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(rp.PostId) AS TotalPosts,
        SUM(rp.ViewCount) AS TotalViews,
        AVG(rp.Score) AS AverageScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5  -- Top 5 recent questions per user
    GROUP BY 
        rp.OwnerDisplayName
)
SELECT 
    ps.OwnerDisplayName,
    ps.TotalPosts,
    ps.TotalViews,
    ps.AverageScore,
    u.Reputation,
    u.Views AS UserViews,
    u.EmailHash
FROM 
    PostStats ps
JOIN 
    Users u ON ps.OwnerDisplayName = u.DisplayName
ORDER BY 
    ps.TotalPosts DESC,
    ps.TotalViews DESC
LIMIT 10;
