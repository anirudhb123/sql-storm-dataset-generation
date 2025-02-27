WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        1 AS RecursionLevel
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Selecting only close and reopen actions

    UNION ALL

    SELECT 
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        r.RecursionLevel + 1
    FROM 
        PostHistory ph
    INNER JOIN 
        RecursivePostHistory r ON ph.PostId = r.PostId
    WHERE 
        ph.CreationDate < r.CreationDate -- Ensuring chronological order
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        MAX(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS HasUpvote,
        MAX(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS HasDownvote,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.Score, p.ViewCount
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCounts
    FROM 
        RecursivePostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Filtering only closed posts
    GROUP BY 
        ph.PostId
),
FinalPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        cp.CloseCounts,
        COALESCE(rp.HasUpvote, 0) AS HasUpvote,
        COALESCE(rp.HasDownvote, 0) AS HasDownvote
    FROM 
        RecentPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.Id = cp.PostId
)
SELECT 
    f.Title,
    f.CreationDate,
    f.LastActivityDate,
    f.Score,
    f.ViewCount,
    f.CommentCount,
    COALESCE(f.CloseCounts, 0) AS TotalClosures,
    CASE 
        WHEN f.HasUpvote = 1 THEN 'Yes'
        ELSE 'No'
    END AS Upvoted,
    CASE 
        WHEN f.HasDownvote = 1 THEN 'Yes'
        ELSE 'No'
    END AS Downvoted
FROM 
    FinalPosts f
WHERE 
    f.CommentCount > 0 
    AND COALESCE(f.CloseCounts, 0) > 1 -- Only those closed multiple times
ORDER BY 
    f.Score DESC, f.ViewCount DESC, f.CreationDate ASC;
