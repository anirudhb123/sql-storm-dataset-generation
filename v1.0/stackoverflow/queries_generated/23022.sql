WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
),
PopularQuestions AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score,
        rp.ViewCount,
        ((rp.Upvotes - rp.Downvotes) / NULLIF(rp.ViewCount, 0))::decimal AS EngagementScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostTypeId = 1 -- Only questions
        AND rp.Rank <= 10
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasonNames,
        COUNT(ph.Id) AS CloseReasonCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Checking for closed and reopened
    GROUP BY 
        ph.PostId
),
EngagingPosts AS (
    SELECT 
        pq.PostId,
        pq.Title,
        pq.Score,
        pq.ViewCount,
        cr.CloseReasonNames,
        COALESCE(cr.CloseReasonCount, 0) AS CloseCount
    FROM 
        PopularQuestions pq
    LEFT JOIN 
        CloseReasons cr ON pq.PostId = cr.PostId
)
SELECT 
    ep.PostId,
    ep.Title,
    ep.Score,
    ep.ViewCount,
    ep.CloseCount,
    CASE 
        WHEN ep.CloseCount > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = ep.PostId) AS UserBadgeCount
FROM 
    EngagingPosts ep
WHERE 
    ep.CloseCount IS NULL OR ep.CloseCount < 3
ORDER BY 
    ep.Score DESC, 
    ep.ViewCount DESC
LIMIT 20;
