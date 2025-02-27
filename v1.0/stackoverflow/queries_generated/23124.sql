WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        u.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN rp.ViewCount = 0 THEN 'No views'
            WHEN rp.ViewCount > 100 THEN 'High views'
            ELSE 'Moderate views'
        END AS ViewCategory
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.PostRank <= 5
),
PostStats AS (
    SELECT 
        fp.PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpvoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownvoteCount,
        fp.ViewCategory,
        MIN(ph.CreationDate) AS FirstHistoryDate,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Comments c ON c.PostId = fp.PostId
    LEFT JOIN 
        Votes v ON v.PostId = fp.PostId
    LEFT JOIN 
        PostHistory ph ON ph.PostId = fp.PostId
    GROUP BY 
        fp.PostId, fp.ViewCategory
),
FinalResults AS (
    SELECT 
        s.PostId,
        s.Title,
        s.CreationDate,
        s.ViewCount,
        s.CommentCount,
        s.UpvoteCount,
        s.DownvoteCount,
        s.ViewCategory,
        CASE 
            WHEN s.CommentCount > 0 THEN 'Commented'
            ELSE 'Not commented'
        END AS CommentStatus,
        CASE 
            WHEN s.FirstHistoryDate IS NULL THEN 'No history'
            ELSE 'Has history'
        END AS HistoryStatus,
        DATE_PART('year', AGE(s.FirstHistoryDate)) AS YearsSinceFirstHistory
    FROM 
        PostStats s
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    CommentCount,
    UpvoteCount,
    DownvoteCount,
    ViewCategory,
    CommentStatus,
    HistoryStatus,
    YearsSinceFirstHistory
FROM 
    FinalResults
WHERE 
    YearsSinceFirstHistory > 2 -- Consider only posts with history older than 2 years
ORDER BY 
    UpvoteCount DESC, 
    ViewCount DESC
LIMIT 50;
