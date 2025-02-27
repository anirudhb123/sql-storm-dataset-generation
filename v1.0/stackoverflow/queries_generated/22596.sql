WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rnk,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS comment_count,
        SUM(v.BountyAmount) AS total_bounty,
        COALESCE(NULLIF(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0), 0) - 
        COALESCE(NULLIF(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0), 0) AS upvote_downvote_diff,
        (SELECT COUNT(*) FROM Votes v2 WHERE v2.PostId = p.Id AND v2.VoteTypeId IN (2, 3)) AS vote_count
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days' 
        AND p.PostTypeId IN (1, 2)
    GROUP BY 
        p.Id
),
PostMetrics AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.comment_count,
        rp.total_bounty,
        rp.upvote_downvote_diff,
        rp.vote_count,
        CASE
            WHEN rp.rnk <= 5 THEN 'Top 5'
            WHEN rp.rnk <= 10 THEN 'Top 10'
            ELSE 'Others'
        END AS RankCategory
    FROM 
        RankedPosts rp
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT CONCAT(ph.Comment, ' on ', TO_CHAR(ph.CreationDate, 'YYYY-MM-DD HH24:MI:SS')), '; ') AS HistoryComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- closed and reopened
    GROUP BY 
        ph.PostId
)
SELECT
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.comment_count,
    pm.total_bounty,
    pm.upvote_downvote_diff,
    pm.vote_count,
    pm.RankCategory,
    COALESCE(phd.HistoryComments, 'No history available') AS PostHistoryComments
FROM 
    PostMetrics pm
LEFT JOIN 
    PostHistoryDetails phd ON pm.PostId = phd.PostId
WHERE 
    pm.vote_count >= 10 -- filter to only include posts with at least 10 total votes
    AND pm.upvote_downvote_diff > 3 -- more upvotes than downvotes
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC;


