WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVotes,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)) / 3600 AS AgeInHours,
        COALESCE((
            SELECT COUNT(c.Id)
            FROM Comments c 
            WHERE c.PostId = p.Id
        ), 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON ph.Comment::int = ctr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AgeInHours,
        rp.CommentCount,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        COALESCE(cp.CloseReasons, 'None') AS CloseReasons,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.AgeInHours < 24 AND rp.UpVotes = 0 THEN 'New Post with No Upvotes'
            WHEN rp.Score < 0 THEN 'Negative Score'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AgeInHours,
    ps.CommentCount,
    ps.CloseCount,
    ps.CloseReasons,
    ps.UpVotes,
    ps.DownVotes,
    ps.PostCategory
FROM 
    PostStatistics ps
WHERE 
    ps.CloseCount < 1 -- Exclude closed posts
    AND ps.AgeInHours < 72 -- Consider only posts that are younger than 3 days
ORDER BY 
    ps.ViewCount DESC NULLS LAST, 
    ps.Score DESC NULLS LAST;
