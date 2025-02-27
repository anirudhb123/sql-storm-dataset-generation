
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS LatestPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS APPLY 
        (SELECT DISTINCT tag.TagName 
         FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS tag
         LEFT JOIN Tags t ON tag.value = t.TagName) t
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount, u.DisplayName, u.Reputation
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 2 THEN ph.CreationDate END) AS InitialBodyEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 4 THEN ph.CreationDate END) AS LastTitleEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    rp.Tags,
    phs.InitialBodyEditDate,
    phs.LastTitleEditDate,
    phs.CloseReopenCount,
    rp.LatestPostRank
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.LatestPostRank = 1 
ORDER BY 
    rp.ViewCount DESC, rp.OwnerReputation DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
