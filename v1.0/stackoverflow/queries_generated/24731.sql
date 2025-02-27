WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn_latest,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotesCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id
), 
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        HOUR(ph.CreationDate) AS EditHour,
        COUNT(ph.Id) AS EditCount,
        STRING_AGG(ph.Comment, '; ') AS EditComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
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
        CloseReasonTypes cr ON cr.Id = CAST(ph.Comment AS INT)
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
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
