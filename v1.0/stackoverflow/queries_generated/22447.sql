WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        MAX(b.Class) OVER (PARTITION BY p.OwnerUserId) AS MaxBadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= DATEADD(DAY, -30, CURRENT_TIMESTAMP)
        AND (p.Tags ILIKE '%sql%' OR p.Body ILIKE '%sql%')
),

FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        RankScore,
        CommentCount,
        MaxBadgeClass
    FROM 
        RankedPosts
    WHERE 
        (CommentCount > 5 OR MaxBadgeClass = 1) -- Considering high comment interaction or high reputation
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.Comment AS CloseReason,
        COUNT(ph.Id) AS ClosureCount,
        MIN(ph.CreationDate) AS FirstClosedDate,
        STRING_AGG(DISTINCT ph.UserDisplayName, ', ') AS Closers
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened posts
    GROUP BY 
        ph.PostId
),

FinalResults AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.ViewCount,
        fp.RankScore,
        COALESCE(ph.CloseReason, 'Not Closed') AS CloseReason,
        COALESCE(ph.ClosureCount, 0) AS ClosureCount,
        COALESCE(ph.FirstClosedDate, 'Never') AS FirstClosedDate,
        COALESCE(ph.Closers, 'No one') AS Closers
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        PostHistoryDetails ph ON fp.PostId = ph.PostId
)

SELECT 
    PostId,
    Title,
    ViewCount,
    RankScore,
    CloseReason,
    ClosureCount,
    FirstClosedDate,
    Closers
FROM 
    FinalResults
WHERE 
    (ViewCount > 100 OR RankScore <= 10) -- Filtering for popular or low-ranking posts
ORDER BY 
    RankScore, ViewCount DESC;
