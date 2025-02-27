WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Only consider posts from the last year
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        COALESCE(SUM(vt.Id = 2), 0) AS TotalUpvotes, -- Count of UpMod votes (Upvotes)
        COALESCE(SUM(vt.Id = 3), 0) AS TotalDownvotes, -- Count of DownMod votes (Downvotes)
        COUNT(c.Id) AS CommentCount,
        COALESCE(MAX(bp.Date), '1900-01-01') AS LastBadgeDate -- Last badge received
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes vt ON rp.PostId = vt.PostId
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Badges bp ON rp.OwnerUserId = bp.UserId
    WHERE 
        bp.Date IS NULL OR bp.Date >= NOW() - INTERVAL '6 months' -- Only consider badges received in the last 6 months
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerUserId
),
TopPosts AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.OwnerUserId,
        (TotalUpvotes - TotalDownvotes) AS NetScore,
        DENSE_RANK() OVER (ORDER BY (TotalUpvotes - TotalDownvotes) DESC) AS ScoreRank
    FROM 
        PostMetrics pm
    WHERE 
        pm.TotalUpvotes - pm.TotalDownvotes > 0 -- Filter out non-positive scores
)
SELECT 
    u.DisplayName,
    tp.Title,
    tp.NetScore,
    tp.ScoreRank,
    CASE 
        WHEN tp.ScoreRank = 1 THEN 'Gold Star'
        WHEN tp.ScoreRank <= 5 THEN 'Silver Star'
        ELSE 'Participant'
    END AS ParticipationLevel, 
    ph.Comment AS PostHistoryComment,
    (SELECT string_agg(pt.Name, ', ') 
     FROM PostHistoryTypes pt 
     JOIN PostHistory ph ON pt.Id = ph.PostHistoryTypeId 
     WHERE ph.PostId = tp.PostId
    ) AS PostHistoryTypes,
    CASE 
        WHEN LastBadgeDate > NOW() - INTERVAL '1 month' THEN 'Recently Honored'
        ELSE 'Seasoned Contributor'
    END AS ContributorStatus
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId 
WHERE 
    ph.Comment IS NOT NULL 
ORDER BY 
    tp.ScoreRank;

This query generates a detailed report from the Stack Overflow schema, providing insights into posts made by users within the last year, their interaction metrics, and their contributions to the community. It incorporates complex logic with CTEs, aggregates, and window functions, while also handling unique conditions like badge timing and post history.
