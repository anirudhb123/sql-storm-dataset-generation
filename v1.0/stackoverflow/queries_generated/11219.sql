-- Performance benchmarking query to analyze post activity and user engagement
WITH PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.Id AS UserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS TotalComments,
        COUNT(DISTINCT v.UserId) AS TotalVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Filter for posts created in the last year
    GROUP BY 
        p.Id, u.Id
),
PostHistoryAnalysis AS (
    SELECT 
        p.PostId,
        COUNT(ph.Id) AS EditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    GROUP BY 
        p.PostId
)

SELECT 
    pe.PostId,
    pe.Title,
    pe.CreationDate,
    pe.Score,
    pe.ViewCount,
    pe.AnswerCount,
    pe.CommentCount,
    pe.FavoriteCount,
    pe.OwnerDisplayName,
    pa.EditCount,
    pa.CloseCount,
    pa.ReopenCount,
    pe.TotalComments,
    pe.TotalVotes
FROM 
    PostEngagement pe
LEFT JOIN 
    PostHistoryAnalysis pa ON pe.PostId = pa.PostId
ORDER BY 
    pe.Score DESC, 
    pe.ViewCount DESC;
