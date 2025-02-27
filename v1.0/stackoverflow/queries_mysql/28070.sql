
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
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName ASC SEPARATOR ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS LatestPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT DISTINCT TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', number), '><', -1)) AS tag FROM Posts p JOIN (SELECT @row := @row + 1 AS number FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) num, (SELECT @row := 0) init) AS numbers) AS tag ON true
    LEFT JOIN 
        Tags t ON tag = t.TagName
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
LIMIT 20;
