
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        SUM(CASE WHEN vt.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS Upvotes,
        SUM(CASE WHEN vt.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS Downvotes
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes vt ON p.Id = vt.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
PostHistoryCTE AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.Comment,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13, 14)
),
TaggedPosts AS (
    SELECT 
        p.Id AS TagPostId,
        GROUP_CONCAT(t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p 
    JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS tag
         FROM 
         (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
          UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
          WHERE numbers.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) + 1) AS tag
    ) AS tag ON TRUE
    JOIN 
        Tags t ON tag.tag = t.TagName
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CreationDate,
    rp.RankByScore,
    rp.Upvotes,
    rp.Downvotes,
    COALESCE(ph.LastClosed, 'Never Closed') AS LastCloseComment,
    tp.Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    (SELECT 
         ph.PostId, 
         ph.Comment AS LastClosed,
         ph.CreationDate
     FROM 
         PostHistoryCTE ph 
     WHERE 
         ph.HistoryRank = 1 AND ph.PostHistoryTypeId = 10) ph ON rp.PostId = ph.PostId
LEFT JOIN 
    TaggedPosts tp ON rp.PostId = tp.TagPostId
WHERE 
    rp.RankByScore <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 100;
