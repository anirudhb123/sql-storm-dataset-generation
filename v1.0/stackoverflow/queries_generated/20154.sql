WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankPerType,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),

MaxScores AS (
    SELECT 
        PostTypeId,
        MAX(Score) AS MaxScore
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        pt.Name AS PostTypeName,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN 
        Posts pos ON ph.PostId = pos.Id
    JOIN 
        PostTypes pt ON pos.PostTypeId = pt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Only considering closed/reopened posts
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.RankPerType,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    COALESCE(m.MaxScore, 0) AS MaxScoreForType,
    CASE 
        WHEN ph.PostId IS NOT NULL THEN 'Closed/Reopened'
        ELSE 'Active'
    END AS PostStatus,
    STRING_AGG(DISTINCT ph.CloseReason, ', ') AS CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    MaxScores m ON rp.PostTypeId = m.PostTypeId
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId
WHERE 
    (rp.RankPerType <= 5 OR (rp.CommentCount > 10 AND rp.UpVoteCount > rp.DownVoteCount))
    AND (ph.CreationDate IS NULL OR ph.CreationDate > rp.CreationDate)
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.RankPerType, m.MaxScore, ph.PostId
ORDER BY 
    rp.Score DESC, rp.CommentCount DESC;
