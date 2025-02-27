WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Considering only BountyStart and BountyClose
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score > (SELECT AVG(Score) FROM Posts)
),
CloseReasonStats AS (
    SELECT 
        p.Id AS PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN CAST(ph.Comment AS INT) END) AS CloseReasonId,
        COUNT(DISTINCT ph.UserId) AS CloseVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Considering Close and Reopen
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        COALESCE(cos.CloseReasonId, 0) AS CloseReasonId,
        COALESCE(cos.CloseVoteCount, 0) AS CloseVoteCount,
        rp.CommentCount,
        rp.TotalBounty
    FROM 
        RankedPosts rp
    LEFT JOIN 
        CloseReasonStats cos ON rp.PostId = cos.PostId
    WHERE 
        rp.rn <= 5  -- Get top 5 latest posts for each type
)
SELECT
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.CommentCount,
    tp.TotalBounty,
    CASE 
        WHEN tp.CloseReasonId IS NULL THEN 'Not Closed'
        WHEN tp.CloseReasonId IS NOT NULL THEN (
            SELECT Name FROM CloseReasonTypes WHERE Id = tp.CloseReasonId
        )
    END AS CloseReason,
    CASE 
        WHEN tp.CloseVoteCount >= 5 THEN 'Highly Controversial'
        ELSE 'Regular'
    END AS ControversialStatus
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewCount DESC, tp.CreationDate ASC;

This SQL query generates a report about popular posts from the last year, integrating complex constructs such as CTEs, outer joins, window functions, aggregations, and conditional logic. It includes complex predicates for filtering, where it only returns posts above the average score. It also calculates additional metrics for insight into user engagement and post status, addressing corner cases such as prior closure reasons.
