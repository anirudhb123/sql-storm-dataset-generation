
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        p.Tags,
        COALESCE(NULLIF(p.Body, ''), 'No content provided') AS BodyContent,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.Tags, p.Body
),
ClosedPostHistories AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        GROUP_CONCAT(DISTINCT c.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN 
        CloseReasonTypes c ON CAST(ph.Comment AS UNSIGNED) = c.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.BodyContent,
    rp.Score,
    rp.CommentCount,
    rp.UpvoteCount,
    rp.DownvoteCount,
    cp.LastClosedDate,
    cp.CloseReasons,
    CASE 
        WHEN rp.Rank = 1 THEN 'Most Recent'
        ELSE 'Older Post'
    END AS PostRankCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPostHistories cp ON rp.PostId = cp.PostId
WHERE 
    (rp.CommentCount > 5 OR rp.Score >= 10)
    AND (cp.LastClosedDate IS NULL OR cp.LastClosedDate < NOW() - INTERVAL 15 DAY)
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 50;
