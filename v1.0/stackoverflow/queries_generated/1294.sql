WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(AVG(v.BountyAmount), 0) AS AverageBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::jsonb @> jsonb_build_object('CloseReasonId', cr.Id)::jsonb
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.AverageBounty,
    c.LastClosedDate,
    COALESCE(c.CloseReasons, 'No close reasons') AS CloseReasons,
    (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = ps.OwnerUserId AND Score > ps.Score) AS HigherScoringPosts
FROM 
    PostStatistics ps
LEFT JOIN 
    ClosedPosts c ON ps.PostId = c.PostId
WHERE 
    ps.Rank <= 5 -- Get top 5 posts per user
ORDER BY 
    ps.Score DESC;
