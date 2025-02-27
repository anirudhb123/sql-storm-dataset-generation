WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentsCount,
        SUM(v.VoteTypeId = 2) AS UpVotesCount,
        SUM(v.VoteTypeId = 3) AS DownVotesCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY SUM(v.VoteTypeId = 2) DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.PostTypeId
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS ClosedDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId
), 
PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerName,
        rp.CommentsCount,
        rp.UpVotesCount,
        rp.DownVotesCount,
        COALESCE(cp.ClosedDate, 'Not Closed') AS ClosedDate,
        COALESCE(cp.CloseReasons, 'No reasons') AS CloseReasons,
        CASE 
            WHEN rp.UpVotesCount > rp.DownVotesCount THEN 'Popular'
            WHEN rp.UpVotesCount < rp.DownVotesCount THEN 'Unpopular'
            ELSE 'Neutral'
        END AS PostPopularity,
        CASE 
            WHEN rp.CreationDate < NOW() - INTERVAL '7 days' THEN 'Old'
            ELSE 'Recent'
        END AS PostAge
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.CommentsCount > 0 AND
        (rp.UpVotesCount IS NOT NULL OR rp.DownVotesCount IS NOT NULL)
)
SELECT 
    ps.Title,
    ps.OwnerName,
    ps.CommentsCount,
    ps.UpVotesCount,
    ps.DownVotesCount,
    ps.ClosedDate,
    ps.CloseReasons,
    ps.PostPopularity,
    ps.PostAge
FROM 
    PostSummary ps
WHERE 
    ps.PostRank <= 5
ORDER BY 
    ps.UpVotesCount DESC, ps.CommentsCount DESC;

This SQL query involves multiple CTEs to calculate the rank of posts based on upvotes and the number of comments, determines if they have been closed along with the reasons, and summarizes the post data enriching it with popularity and age metrics. The final selection gets the top-ranked posts with relevant information and handles NULL cases effectively while implementing various SQL constructs including window functions, outer joins, aggregates, and CASE logic.
