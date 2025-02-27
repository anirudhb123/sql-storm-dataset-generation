WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND   -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Last year
), 
PostMetrics AS (
    SELECT 
        rp.PostId, 
        rp.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpvoteCount,  -- Count of Upvotes
        SUM(v.VoteTypeId = 3) AS DownvoteCount -- Count of Downvotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        Votes v ON v.PostId = rp.PostId
    WHERE 
        rp.OwnerRank = 1 -- Only most recent question per user
    GROUP BY 
        rp.PostId, rp.Title
), 
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate, 
        MAX(ph.CreationDate) AS RecentCloseDate,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Closed or Reopened
    GROUP BY 
        ph.PostId, ph.CreationDate
), 
PostsWithNoActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title
    FROM 
        Posts p
    LEFT JOIN 
        PostLinks pl ON pl.PostId = p.Id OR pl.RelatedPostId = p.Id
    WHERE 
        p.LastActivityDate < NOW() - INTERVAL '6 months' AND 
        pl.Id IS NULL -- No links
)
SELECT 
    pm.PostId,
    pm.Title,
    COALESCE(c.RecentCloseDate, 'Never Closed') AS RecentCloseDate,
    COALESCE(pm.CommentCount, 0) AS CommentCount,
    COALESCE(pm.UpvoteCount, 0) AS UpvoteCount,
    COALESCE(pm.DownvoteCount, 0) AS DownvoteCount,
    CASE 
        WHEN wpm.PostId IS NOT NULL THEN 'Inactive' 
        ELSE 'Active' 
    END AS PostStatus
FROM 
    PostMetrics pm
LEFT JOIN 
    ClosedPosts c ON c.PostId = pm.PostId
LEFT JOIN 
    PostsWithNoActivity wpm ON wpm.PostId = pm.PostId
ORDER BY 
    pm.UpvoteCount DESC, pm.CommentCount DESC
LIMIT 100;
