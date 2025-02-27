-- Performance benchmarking query to analyze posts and user engagement
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.Reputation AS UserReputation,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
),
AggregatedStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.PostTypeId
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.UserReputation,
    rp.OwnerDisplayName,
    phc.EditCount,
    ats.TotalPosts,
    ats.TotalViews,
    ats.AvgUserReputation
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryCounts phc ON rp.PostId = phc.PostId
CROSS JOIN 
    (SELECT 
        TotalPosts, TotalViews, AvgUserReputation 
     FROM 
        AggregatedStats 
     WHERE 
        PostTypeId = 1) ats -- Example: filter for Questions (PostTypeId = 1)
WHERE 
    rp.Rank <= 10; -- Fetch top 10 ranked posts
