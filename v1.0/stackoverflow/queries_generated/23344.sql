WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        PostTypeId, 
        CreationDate, 
        Score,
        CommentCount,
        AvgUserReputation
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 10
),
PostWithHistory AS (
    SELECT 
        t.PostId,
        t.Title,
        t.PostTypeId,
        t.Score,
        ph.PostHistoryTypeId,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        TopPosts t
    LEFT JOIN 
        PostHistory ph ON t.PostId = ph.PostId
    GROUP BY 
        t.PostId, t.Title, t.PostTypeId, t.Score, ph.PostHistoryTypeId
)
SELECT 
    t.PostId,
    t.Title,
    t.PostTypeId,
    COALESCE(t.Score, 0) AS AdjustedScore,
    COALESCE(AvgUserReputation, 0) AS AvgUserReputation,
    CASE WHEN t.Score > 100 THEN 'Very Popular' 
         WHEN t.Score BETWEEN 50 AND 100 THEN 'Popular' 
         ELSE 'Less Popular' END AS PopularityCategory,
    ph.HistoryCount,
    MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 'Closed' ELSE 'Active' END) AS PostStatus
FROM 
    TopPosts t
LEFT JOIN 
    PostWithHistory ph ON t.PostId = ph.PostId
GROUP BY 
    t.PostId, t.Title, t.PostTypeId, t.Score, AvgUserReputation, ph.HistoryCount
ORDER BY 
    AdjustedScore DESC, t.CreationDate DESC
FETCH FIRST 15 ROWS ONLY
UNION ALL 
SELECT 
    NULL AS PostId,
    'Summary of Top Posts' AS Title,
    NULL AS PostTypeId,
    SUM(AdjustedScore) AS TotalScore,
    AVG(AvgUserReputation) AS OverallAvgReputation,
    'N/A' AS PopularityCategory,
    COUNT(*) AS HistoryCount,
    'Aggregate' AS PostStatus
FROM 
    (SELECT COALESCE(t.Score, 0) AS AdjustedScore, 
            COALESCE(AvgUserReputation, 0) AS AvgUserReputation
     FROM TopPosts t
     LEFT JOIN PostWithHistory ph ON t.PostId = ph.PostId
    ) AS cumulative
HAVING SUM(AdjustedScore) IS NOT NULL
ORDER BY TotalScore DESC;
