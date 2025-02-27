WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) OVER (PARTITION BY p.Id) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
), 

ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON ph.Comment::int = ctr.Id -- assuming Comment contains close reason ID
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- close and reopen events
    GROUP BY 
        ph.PostId
), 

PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.Rank,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        ph.LastClosedDate,
        ph.CloseReasonNames
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPostHistory ph ON rp.PostId = ph.PostId
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.Rank,
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    pd.LastClosedDate,
    CASE 
        WHEN pd.LastClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    COALESCE(pd.CloseReasonNames, 'No close reason') AS CloseReasons
FROM 
    PostDetails pd
WHERE 
    pd.Rank <= 5 -- Top 5 per post type
ORDER BY 
    pd.Score DESC, pd.PostId 

UNION ALL

SELECT 
    0 AS PostId, 
    'Aggregate' AS Title, 
    SUM(pd.Score) AS TotalScore,
    NULL AS Rank, 
    SUM(pd.CommentCount) AS TotalComments,
    SUM(pd.UpVoteCount) AS TotalUpVotes,
    SUM(pd.DownVoteCount) AS TotalDownVotes,
    NULL AS LastClosedDate,
    NULL AS CloseReasons
FROM 
    PostDetails pd
WHERE 
    pd.LastClosedDate IS NULL; -- Summary for open posts
