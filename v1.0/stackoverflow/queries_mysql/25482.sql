
WITH DetailedPostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2 
    LEFT JOIN 
        (
            SELECT 
                p.Id, 
                SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1) AS TagName
            FROM 
                Posts p
            INNER JOIN 
                (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n 
            ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= n.n - 1
        ) AS t ON p.Id = t.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, u.Reputation
),
PostHistoryAnalysis AS (
    SELECT
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS FirstClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS TotalCloseVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS TotalReopenVotes
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    dpi.PostId,
    dpi.Title,
    dpi.Body,
    dpi.CreationDate,
    dpi.Score,
    dpi.ViewCount,
    dpi.OwnerDisplayName,
    dpi.OwnerReputation,
    dpi.Tags,
    dpi.CommentCount,
    dpi.AnswerCount,
    pha.FirstClosedDate,
    pha.LastClosedDate,
    pha.TotalCloseVotes,
    pha.TotalReopenVotes
FROM 
    DetailedPostInfo dpi
LEFT JOIN 
    PostHistoryAnalysis pha ON dpi.PostId = pha.PostId
ORDER BY 
    dpi.CreationDate DESC
LIMIT 50;
