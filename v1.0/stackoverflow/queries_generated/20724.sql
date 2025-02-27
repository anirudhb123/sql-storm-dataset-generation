WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > current_date - interval '1 year'
),

PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.RankScore,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 3 -- Top 3 ranked posts per post type
),

PostVoteData AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),

ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS ClosedReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id -- Assuming Comment field contains CloseReasonId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Only considering close/reopen actions
    GROUP BY 
        ph.PostId
)

SELECT 
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.ViewCount,
    pp.OwnerDisplayName,
    pd.TotalUpvotes,
    pd.TotalDownvotes,
    pp.CommentCount,
    COALESCE(cpr.ClosedReasons, 'Not Closed') AS ClosedReasons
FROM 
    PopularPosts pp
JOIN 
    PostVoteData pd ON pp.PostId = pd.PostId
LEFT JOIN 
    ClosedPostReasons cpr ON pp.PostId = cpr.PostId
ORDER BY 
    pp.Score DESC, pp.CreationDate DESC
LIMIT 50;

This query retrieves a list of popular posts from the past year, ranking them by score while also displaying various metrics such as upvotes, downvotes, comments, and any reasons for closure if applicable. It cleverly combines several SQL constructs, including CTEs, window functions, aggregate functions, and string aggregation, while incorporating outer joins and NULL handling to account for posts that may not have been closed or have no votes.
