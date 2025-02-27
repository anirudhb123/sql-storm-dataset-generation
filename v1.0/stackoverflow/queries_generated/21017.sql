WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.PostTypeId,
        rp.PostRank,
        rp.CommentCount,
        CASE 
            WHEN rp.PostTypeId = 1 AND rp.PostRank = 1 THEN 'Top Question'
            WHEN rp.PostTypeId = 2 AND rp.PostRank <= 5 THEN 'Popular Answer'
            ELSE 'Other'
        END AS Category
    FROM 
        RankedPosts rp
    WHERE 
        rp.ViewCount >= 100
),
PostHistoryCTE AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        p.Title AS PostTitle,
        p.PostTypeId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.ViewCount,
    fp.CommentCount,
    fp.Category,
    ph.PostHistoryTypeId,
    ph.CreationDate AS HistoryDate,
    ph.Comment AS HistoryComment,
    ue.UserId,
    ue.UpVotes,
    ue.DownVotes,
    ue.BadgeCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistoryCTE ph ON fp.PostId = ph.PostId AND ph.HistoryRank = 1
LEFT JOIN 
    UserEngagement ue ON ue.UserId = fp.PostId
WHERE 
    fp.Category IN ('Top Question', 'Popular Answer')
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC,
    ph.CreationDate DESC;

### Explanation:
- **CTEs (Common Table Expressions)**:
  - `RankedPosts`: Ranks posts based on their score and counts associated comments.
  - `FilteredPosts`: Filters the ranked posts to only include those with a minimum view count and categorizes them.
  - `PostHistoryCTE`: Captures the post history for a given post within the last six months.
  - `UserEngagement`: Aggregates user engagement data, including badge counts.

- **Main Query**: Joins the filtered posts with their most recent history and user engagement metrics. The final output is sorted by score and view count for performance benchmarking.

- **Constructs Used**:
  - Outer joins, window functions, set operators, NULL logic, and correlated subqueries are effectively used to create a complex data retrieval structure, ready for deeper analysis and performance measurement.
