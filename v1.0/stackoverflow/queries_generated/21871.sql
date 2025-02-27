WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
DiscussionPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Count AS CommentsCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id, p.Count
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- For post closed or reopened events
    GROUP BY 
        ph.PostId
),
AggregateVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS TotalUpvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS TotalDownvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    dp.CommentsCount,
    COALESCE(dp.Upvotes, 0) AS Upvotes,
    COALESCE(dp.Downvotes, 0) AS Downvotes,
    cr.CloseReasons,
    AVG(avc.TotalUpvotes - avc.TotalDownvotes) OVER () AS AverageVoteDifference,
    CASE 
        WHEN dp.Upvotes IS NULL THEN 'No Votes'
        WHEN dp.Upvotes > dp.Downvotes THEN 'More Upvotes'
        ELSE 'More Downvotes'
    END AS VoteAnalysis
FROM 
    RankedPosts rp
LEFT JOIN 
    DiscussionPosts dp ON rp.PostId = dp.PostId
LEFT JOIN 
    CloseReasons cr ON rp.PostId = cr.PostId
LEFT JOIN 
    AggregateVoteCounts avc ON rp.PostId = avc.PostId
WHERE 
    rp.ScoreRank <= 5 OR cr.CloseReasons IS NOT NULL
ORDER BY 
    rp.CreationDate DESC;
