WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS TotalUpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS TotalDownVotes,
        SUM(v.BountyAmount) AS TotalBounty,
        ROW_NUMBER() OVER(PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
),
CommentStatistics AS (
    SELECT 
        PostId,
        MAX(CreationDate) AS LastCommentDate,
        COUNT(*) AS CommentsInLastMonth
    FROM 
        Comments
    WHERE 
        CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseVotes
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.PostTypeId,
    ps.CommentCount,
    ps.TotalUpVotes,
    ps.TotalDownVotes,
    ps.TotalBounty,
    COALESCE(cs.LastCommentDate, 'No comments') AS LastCommentDate,
    COALESCE(cs.CommentsInLastMonth, 0) AS CommentsInLastMonth,
    COALESCE(cp.CloseVotes, 0) AS CloseVotes,
    CASE 
        WHEN ps.TotalUpVotes > ps.TotalDownVotes THEN 'Positive'
        WHEN ps.TotalDownVotes > ps.TotalUpVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    CASE 
        WHEN ps.CommentCount > 10 THEN 'Popular Post'
        ELSE 'Less Popular Post'
    END AS Popularity
FROM 
    PostStatistics ps
LEFT JOIN 
    CommentStatistics cs ON ps.PostId = cs.PostId
LEFT JOIN 
    ClosedPosts cp ON ps.PostId = cp.PostId
WHERE 
    ps.rn <= 10;
