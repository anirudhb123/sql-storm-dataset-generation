WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        Score,
        ParentId,
        0 AS Depth
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ParentId,
        r.Depth + 1 AS Depth
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostVoteStatistics AS (
    SELECT 
        PostId,
        VoteTypeId,
        COUNT(*) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        PostId, VoteTypeId
),
PostCommentCount AS (
    SELECT 
        PostId,
        COUNT(*) as CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
),
PostCloseHistory AS (
    SELECT 
        PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        PostId
),
AggregatedPostInfo AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(vs.VoteCount, 0) AS TotalVotes,
        COALESCE(pc.CommentCount, 0) AS TotalComments,
        COALESCE(ph.CloseCount, 0) AS TotalCloses,
        r.Depth,
        p.Score
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteStatistics vs ON p.Id = vs.PostId
    LEFT JOIN 
        PostCommentCount pc ON p.Id = pc.PostId
    LEFT JOIN 
        PostCloseHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        RecursivePostHierarchy r ON p.Id = r.Id
)
SELECT 
    a.PostId,
    a.Title,
    a.ViewCount,
    a.TotalVotes,
    a.TotalComments,
    a.TotalCloses,
    a.Depth,
    CASE 
        WHEN a.TotalCloses > 0 THEN 'Closed'
        WHEN a.Score >= 10 THEN 'Popular'
        ELSE 'Normal'
    END AS PostStatus,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    AggregatedPostInfo a
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(a.Tags, ',')) AS TagName
    ) AS t ON TRUE 
GROUP BY 
    a.PostId, a.Title, a.ViewCount, a.TotalVotes, a.TotalComments, a.TotalCloses, a.Depth
ORDER BY 
    a.Score DESC, a.ViewCount DESC
LIMIT 50;
