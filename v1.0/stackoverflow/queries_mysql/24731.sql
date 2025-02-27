
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn_latest,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
), 
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        HOUR(ph.CreationDate) AS EditHour,
        COUNT(ph.Id) AS EditCount,
        GROUP_CONCAT(ph.Comment SEPARATOR '; ') AS EditComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId, HOUR(ph.CreationDate)
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS ClosedDate,
        cr.Name AS CloseReasonName
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        CloseReasonTypes cr ON cr.Id = CAST(ph.Comment AS UNSIGNED)
    WHERE 
        ph.PostHistoryTypeId = 10 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    COALESCE(dp.ClosedDate, NULL) AS ClosedDate,
    COALESCE(dp.CloseReasonName, 'Not Closed') AS CloseReason,
    rp.UpVotesCount,
    rp.DownVotesCount,
    CASE 
        WHEN rp.UpVotesCount > rp.DownVotesCount THEN 'Positively Rated'
        WHEN rp.DownVotesCount > rp.UpVotesCount THEN 'Negatively Rated'
        ELSE 'Neutral'
    END AS RatingType,
    phd.EditHour,
    phd.EditCount,
    phd.EditComments
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts dp ON rp.PostId = dp.PostId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.rn_latest = 1 
    AND (rp.ViewCount > 100 OR (rp.Score > 0 AND dp.PostId IS NULL))
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 50;
