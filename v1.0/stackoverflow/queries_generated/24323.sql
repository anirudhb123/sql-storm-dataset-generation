WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
),
AggregatedVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > CURRENT_DATE - INTERVAL '1 month'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        av.TotalUpvotes,
        av.TotalDownvotes,
        COALESCE(SUM(CASE WHEN phs.ChangeCount IS NOT NULL THEN phs.ChangeCount ELSE 0 END), 0) AS RecentHistoryChanges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        AggregatedVotes av ON rp.PostId = av.PostId
    LEFT JOIN 
        PostHistoryStats phs ON rp.PostId = phs.PostId
    WHERE 
        rp.RankByScore <= 10
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.CommentCount, av.TotalUpvotes, av.TotalDownvotes
),
FinalOutput AS (
    SELECT 
        fp.*,
        CASE
            WHEN RecentHistoryChanges > 5 THEN 'Highly Active'
            WHEN RecentHistoryChanges BETWEEN 1 AND 5 THEN 'Moderately Active'
            ELSE 'Low Activity'
        END AS ActivityLevel,
        TAGS AS PostTags
    FROM 
        FilteredPosts fp
)
SELECT 
    *,
    STRING_AGG(Tags, ', ') AS AllTags,
    COALESCE(NULLIF(DisplayName, ''), 'Anonymous') AS UserDisplay
FROM 
    FinalOutput fpo
LEFT JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = fpo.PostId)
GROUP BY 
    fpo.PostId, fpo.Title, fpo.CreationDate, fpo.ViewCount, fpo.Score, fpo.CommentCount, 
    fpo.TotalUpvotes, fpo.TotalDownvotes, fpo.RecentHistoryChanges, fpo.ActivityLevel
ORDER BY 
    fpo.Score DESC, fpo.CreationDate ASC;
This SQL query performs the following operations:

1. It establishes a series of Common Table Expressions (CTEs) to structure the query logically and clearly.
2. `RankedPosts` ranks posts by score within their post types, while counting their comments.
3. `AggregatedVotes` summarizes the vote counts for each post.
4. `PostHistoryStats` counts the changes made to posts in the last month.
5. `FilteredPosts` creates a combined report of the above, applying conditional logic to classify activity levels.
6. Finally, the outer query selects relevant fields and aggregates the tags, while providing a fallback for the user's display name using COALESCE with NULL logic.
  
The aim is to create a comprehensive performance benchmark for recent, highly-rated posts with detailed vote and activity statistics over the past year.
