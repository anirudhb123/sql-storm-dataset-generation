WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPostsByUser,
        LEAD(p.ViewCount) OVER (ORDER BY p.CreationDate) AS NextPostViewCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        COALESCE(rp.NextPostViewCount - rp.ViewCount, 0) AS ViewCountDifference,
        rp.Score,
        rp.UserPostRank,
        rp.TotalPostsByUser
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserPostRank = 1
        AND rp.TotalPostsByUser > 5
),
PostsWithComments AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.ViewCountDifference,
        fp.Score,
        COUNT(c.Id) AS CommentCount,
        CASE 
            WHEN COUNT(c.Id) = 0 THEN 'No Comments'
            ELSE STRING_AGG(c.Text, '; ') 
        END AS CommentText
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Comments c ON fp.PostId = c.PostId
    GROUP BY 
        fp.PostId, fp.Title, fp.CreationDate, fp.ViewCountDifference, fp.Score
)
SELECT 
    p.Title,
    p.CreationDate,
    p.ViewCountDifference,
    p.Score,
    p.CommentCount,
    CASE 
        WHEN p.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus,
    CASE 
        WHEN p.ViewCountDifference < 0 THEN 'Fewer Views than Next Post'
        WHEN p.ViewCountDifference = 0 THEN 'Equal Views to Next Post'
        ELSE 'More Views than Next Post'
    END AS ViewComparison,
    CASE 
        WHEN p.Score IS NULL THEN 'Unscored'
        WHEN p.Score > 0 THEN 'Positive Score'
        WHEN p.Score < 0 THEN 'Negative Score'
        ELSE 'Neutral Score'
    END AS ScoreDescription
FROM 
    PostsWithComments p
WHERE 
    p.Score IS NOT NULL 
    OR EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = p.PostId
        AND v.VoteTypeId IN (2, 3)  -- Considering upvotes and downvotes
    )
ORDER BY 
    p.CreationDate DESC
LIMIT 10;

-- Combine posts with their history, checking for posts that have been closed in the last year
SELECT 
    ph.PostId,
    p.Title,
    ph.CreationDate AS HistoryDate,
    p.Body,
    pt.Name AS PostType,
    COUNT(DISTINCT ph.UserId) AS EditorsCount,
    SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 12) THEN 1 ELSE 0 END) AS ClosedOrDeletedCount
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    ph.CreationDate >= NOW() - INTERVAL '1 year'
    AND ph.PostHistoryTypeId IN (10, 12)  -- Closed or Deleted
GROUP BY 
    ph.PostId, p.Title, ph.CreationDate, p.Body, pt.Name
HAVING 
    EditorsCount > 5
ORDER BY 
    HistoryDate DESC;

-- Union two result sets to show engagement metrics along with edit history
UNION ALL

SELECT 
    p.Id AS PostId,
    p.Title,
    NULL AS HistoryDate,
    p.Body,
    pt.Name AS PostType,
    NULL AS EditorsCount,
    NULL AS ClosedOrDeletedCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.ViewCount > 100 
    AND p.CreationDate >= NOW() - INTERVAL '6 months';
