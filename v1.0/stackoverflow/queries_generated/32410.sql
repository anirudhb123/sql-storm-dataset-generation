WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount, -- Count of upvotes for each post
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount -- Count of downvotes for each post
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last year
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, u.DisplayName
),
PostStatistics AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CreationDate,
        OwnerDisplayName,
        Rank,
        UpvoteCount,
        DownvoteCount,
        (UpvoteCount - DownvoteCount) AS NetVotes, -- Calculating net votes
        CASE WHEN Score > 100 THEN 'High' 
             WHEN Score BETWEEN 50 AND 100 THEN 'Medium' 
             ELSE 'Low' END AS ScoreCategory -- Categorizing scores
    FROM 
        RankedPosts
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ct.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes ct ON ph.Comment::int = ct.Id -- Assuming Comment contains the CloseReasonId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened posts
    GROUP BY 
        ph.PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.CreationDate,
    ps.OwnerDisplayName,
    ps.Rank,
    ps.NetVotes,
    ps.ScoreCategory,
    COALESCE(cp.CloseReasons, 'Not Closed') AS CloseReason
FROM 
    PostStatistics ps
LEFT JOIN 
    ClosedPosts cp ON ps.PostId = cp.PostId
WHERE 
    ps.Rank <= 5 -- Get top 5 posts per type
ORDER BY 
    ps.Score DESC, ps.CreationDate DESC;
