
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        p.AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId, p.Score, p.AcceptedAnswerId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.CreationDate END) AS LastDeletedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeletionCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
               UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         WHERE CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1) t 
    ON p.Id IS NOT NULL
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    ph.LastClosedDate,
    ph.LastDeletedDate,
    ph.ClosureCount,
    ph.DeletionCount,
    tp.Tags,
    CASE 
        WHEN rp.PostRank <= 5 AND ph.ClosureCount > 0 THEN 'Hot '
        WHEN rp.PostRank <= 5 THEN 'Trending '
        ELSE 'Standard '
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistorySummary ph ON rp.PostId = ph.PostId
LEFT JOIN 
    TaggedPosts tp ON rp.PostId = tp.PostId
WHERE 
    rp.PostTypeId = 1 
    AND (ph.LastClosedDate IS NULL OR ph.LastClosedDate < '2024-10-01 12:34:56' - INTERVAL 30 DAY)
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
