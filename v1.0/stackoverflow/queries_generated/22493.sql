WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COALESCE(COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE(COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3), 0) AS Downvotes,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ClosureRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Closed or Reopened
),
PostWithHistories AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.Upvotes,
        rp.Downvotes,
        rp.CommentCount,
        ch.UserDisplayName AS ClosedBy,
        ch.CreationDate AS ClosureDate,
        CASE 
            WHEN ch.ClosureRank = 1 THEN 'Last Closure'
            ELSE NULL
        END AS ClosureStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPostHistory ch ON rp.PostId = ch.PostId
    WHERE 
        rp.Rank <= 10  -- Top 10 posts for each PostType
)
SELECT 
    pwh.PostId,
    pwh.Title,
    pwh.Score,
    pwh.Upvotes,
    pwh.Downvotes,
    pwh.CommentCount,
    pwh.ClosedBy,
    COALESCE(TO_CHAR(pwh.ClosureDate, 'YYYY-MM-DD HH24:MI:SS'), 'Never Closed') AS ClosureDate,
    CASE 
        WHEN pwh.ClosedBy IS NOT NULL THEN 
            CONCAT('Closed by ', pwh.ClosedBy, ' on ', TO_CHAR(pwh.ClosureDate, 'DD Mon YYYY'))
        ELSE 
            'Active'
    END AS PostStatus,
    CASE 
        WHEN pwh.Score > 100 THEN 'Hot'
        WHEN pwh.Score BETWEEN 50 AND 100 THEN 'Warm'
        ELSE 'Cold'
    END AS Temperature
FROM 
    PostWithHistories pwh
ORDER BY 
    pwh.Score DESC, 
    pwh.PostId ASC

UNION ALL 

SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    0 AS Upvotes,
    0 AS Downvotes,
    0 AS CommentCount,
    NULL AS ClosedBy,
    'Never Closed' AS ClosureDate,
    'Active' AS PostStatus,
    'Cold' AS Temperature
FROM 
    Posts p
WHERE 
    p.Id NOT IN (SELECT PostId FROM RankedPosts)  -- Posts that are not in the main ranking
ORDER BY 
    PostId;
