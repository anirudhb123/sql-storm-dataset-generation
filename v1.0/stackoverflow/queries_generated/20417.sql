WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.CreationDate ASC) AS RankWithinType
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days' 
        AND u.Reputation > 1000
),

PostClosedStatus AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS IsClosed,
        ARRAY_AGG(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN c.Name END) AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes c ON ph.Comment::int = c.Id 
    GROUP BY 
        ph.PostId
),

PostVoteAggregate AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    COALESCE(pcs.IsClosed, 0) AS IsClosed,
    CASE
        WHEN pcs.IsClosed = 1 THEN 'Closed'
        ELSE 'Active'
    END AS Status,
    COALESCE(PVA.Upvotes, 0) AS Upvotes,
    COALESCE(PVA.Downvotes, 0) AS Downvotes,
    ARRAY_TO_STRING(pcs.CloseReasons, ', ') AS CloseReasonsList
FROM 
    RankedPosts rp
LEFT JOIN 
    PostClosedStatus pcs ON rp.PostId = pcs.PostId
LEFT JOIN 
    PostVoteAggregate PVA ON rp.PostId = PVA.PostId
WHERE 
    rp.RankWithinType <= 5 
    AND (PVA.Upvotes IS NOT NULL OR PVA.Downvotes IS NOT NULL)
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC;
