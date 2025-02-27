WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        U.Reputation
    FROM 
        Posts p
    INNER JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostVoteDetails AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
CloseReasonCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseReasonCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COALESCE(pvd.Upvotes, 0) AS Upvotes,
        COALESCE(pvd.Downvotes, 0) AS Downvotes,
        COALESCE(crc.CloseReasonCount, 0) AS CloseReasons,
        CASE 
            WHEN rp.Score > 100 THEN 'Hot'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Trending'
            ELSE 'Normal'
        END AS PostCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteDetails pvd ON rp.PostId = pvd.PostId
    LEFT JOIN 
        CloseReasonCounts crc ON rp.PostId = crc.PostId
)
SELECT 
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.Upvotes,
    pm.Downvotes,
    pm.CloseReasons,
    pm.PostCategory,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation
FROM 
    PostMetrics pm
JOIN 
    Users u ON pm.OwnerUserId = u.Id
WHERE 
    pm.CloseReasons < 2
    AND pm.Rank <= 10
ORDER BY 
    pm.Score DESC, pm.CreationDate ASC;

