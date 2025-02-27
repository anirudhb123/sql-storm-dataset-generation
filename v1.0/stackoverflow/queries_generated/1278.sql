WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswer,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.AcceptedAnswerId
),
FilteredPosts AS (
    SELECT 
        rp.*, 
        COALESCE(u.DisplayName, 'Deleted User') AS UserDisplayName,
        u.Reputation
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.Rank <= 5 -- Top 5 posts per user
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened posts
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.CommentCount,
    fp.UserDisplayName,
    fp.Reputation,
    ph.HistoryDate,
    CASE 
        WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
        WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
        ELSE 'N/A'
    END AS StatusChange,
    ph.Comment AS Reason
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistories ph ON fp.PostId = ph.PostId
ORDER BY 
    fp.Reputation DESC, 
    fp.CreationDate DESC;
