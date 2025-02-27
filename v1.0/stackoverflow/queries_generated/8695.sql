WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND -- Only Questions
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- From the last year
),
TopVotedPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 -- Top 5 posts for each user
),
AggregateStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AverageScore,
        SUM(ViewCount) AS TotalViews
    FROM 
        TopVotedPosts
)
SELECT 
    tp.Id,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.Tags,
    tp.OwnerDisplayName,
    ag.TotalPosts,
    ag.AverageScore,
    ag.TotalViews
FROM 
    TopVotedPosts tp
CROSS JOIN 
    AggregateStats ag
ORDER BY 
    tp.Score DESC;
