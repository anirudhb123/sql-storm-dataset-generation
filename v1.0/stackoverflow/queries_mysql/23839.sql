
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS RankScore,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotesCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotesCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentsCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
),

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.RankScore,
        rp.UpVotesCount,
        rp.DownVotesCount,
        rp.CommentsCount,
        CASE 
            WHEN rp.Score > 10 THEN 'High Score'
            WHEN rp.Score BETWEEN 1 AND 10 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 10
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        p.Title AS PostTitle,
        ph.CreationDate AS HistoryDate,
        pht.Name AS HistoryTypeName
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 MONTH
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.UpVotesCount,
    fp.DownVotesCount,
    fp.CommentsCount,
    fp.ScoreCategory,
    COALESCE(phd.HistoryTypeName, 'No Recent Changes') AS RecentHistory,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistoryDetails phd ON fp.PostId = phd.PostId
LEFT JOIN 
    Badges b ON b.UserId = fp.PostId AND b.Class = 1 
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.Score, fp.UpVotesCount, fp.DownVotesCount, fp.CommentsCount, fp.ScoreCategory, phd.HistoryTypeName
ORDER BY 
    fp.Score DESC,
    fp.CommentsCount DESC,
    fp.CreationDate DESC;
