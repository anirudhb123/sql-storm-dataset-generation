WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score > 0
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '30 days' 
    GROUP BY 
        v.PostId, v.VoteTypeId
),
VotingSummary AS (
    SELECT 
        rv.PostId,
        SUM(CASE WHEN rv.VoteTypeId = 2 THEN rv.VoteCount ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN rv.VoteTypeId = 3 THEN rv.VoteCount ELSE 0 END) AS Downvotes
    FROM 
        RecentVotes rv
    GROUP BY 
        rv.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS CloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.OwnerName,
    COALESCE(vs.Upvotes, 0) AS Upvotes,
    COALESCE(vs.Downvotes, 0) AS Downvotes,
    COALESCE(phd.CloseDate, 'No Close') AS ClosureStatus,
    CASE 
        WHEN phd.ReopenDate IS NOT NULL THEN 'Reopened'
        WHEN phd.CloseDate IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN rp.Score IS NULL THEN 'Zero or Unknown Score'
        WHEN rp.Score < 10 THEN 'Low Score'
        WHEN rp.Score BETWEEN 10 AND 50 THEN 'Moderate Score'
        ELSE 'High Score'
    END AS ScoreCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    VotingSummary vs ON rp.PostId = vs.PostId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.rn = 1 
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
