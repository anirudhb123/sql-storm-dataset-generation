
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags,
        u.DisplayName AS OwnerName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id OR t.ExcerptPostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, u.DisplayName
),
PostActivity AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        GROUP_CONCAT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (4, 5) THEN ph.Text END SEPARATOR '; ') AS LastEdits,
        GROUP_CONCAT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.Comment END SEPARATOR '; ') AS CloseReasons
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TopScoringPosts AS (
    SELECT 
        rp.*,
        pa.EditCount,
        pa.LastEditDate,
        pa.LastEdits,
        pa.CloseReasons,
        @rownum := @rownum + 1 AS ScoreRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostActivity pa ON rp.PostId = pa.PostId,
        (SELECT @rownum := 0) r
)
SELECT 
    PostId,
    Title,
    Body,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    Tags,
    OwnerName,
    EditCount,
    LastEditDate,
    LastEdits,
    CloseReasons
FROM 
    TopScoringPosts
WHERE 
    ScoreRank <= 10 
ORDER BY 
    Score DESC, 
    CreationDate DESC;
