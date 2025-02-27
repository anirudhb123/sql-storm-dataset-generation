WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 MONTH'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserId,
        COALESCE(u.DisplayName, 'Deleted User') AS UserDisplayName,
        ph.Comment,
        ph.Text,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    LEFT JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 12, 19) -- Only consider closed, deleted, or moderated posts
),
AggregatedVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
FinalReport AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        COALESCE(av.UpVotes, 0) AS TotalUpVotes,
        COALESCE(av.DownVotes, 0) AS TotalDownVotes,
        CASE WHEN phdd.HistoryDate IS NOT NULL THEN 'Closed/Deleted' ELSE 'Active' END AS PostStatus,
        phdd.UserDisplayName,
        phdd.Comment AS ClosureComment
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryDetails phdd ON rp.PostId = phdd.PostId AND phdd.HistoryRank = 1 
    LEFT JOIN 
        AggregatedVotes av ON rp.PostId = av.PostId
    WHERE 
        rp.Rank <= 10
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    CommentCount,
    TotalUpVotes,
    TotalDownVotes,
    PostStatus,
    UserDisplayName,
    ClosureComment
FROM 
    FinalReport
ORDER BY 
    Score DESC;

This query performs several interesting operations:
- It calculates the top 10 ranked posts from the last month using window functions and joins to collect relevant comment counts.
- It aggregates vote counts separately, handling upvotes and downvotes using conditional aggregation.
- A `WITH` clause selects relevant post history, including details on closures or deletions.
- It combines all this information into a final report that includes metadata about the post’s status and any closure comments from the history.
