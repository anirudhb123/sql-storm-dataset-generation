WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COALESCE(pt.Name, 'Unknown Post Type') AS PostTypeName,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
),
ClosedPostsSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.RankScore,
        rp.UpVotes,
        rp.DownVotes,
        rp.TotalComments,
        COALESCE(cp.LastClosedDate, 'No closures') AS LastClosedDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.RankScore <= 3 -- Limit to top 3 for each post type
)
SELECT 
    cs.PostId,
    cs.Title,
    cs.CreationDate,
    cs.Score,
    cs.ViewCount,
    cs.AnswerCount,
    cs.CommentCount,
    cs.RankScore,
    cs.UpVotes,
    cs.DownVotes,
    cs.TotalComments,
    cs.LastClosedDate
FROM 
    ClosedPostsSummary cs
WHERE 
    cs.LastClosedDate IS NOT NULL 
    OR (cs.LastClosedDate = 'No closures' AND cs.AnswerCount > 0)
ORDER BY 
    cs.Score DESC, cs.Title ASC;

-- Explanation:
-- This query uses Common Table Expressions (CTEs) to first rank posts by score within their type,
-- and then checks their closure history via PostHistory.
-- A detailed summary of closed posts is produced, focusing on the top 3 ranked posts of each type that have either been closed
-- or have comments. It also incorporates aggregates and a potentially complex filter logic combining NULL checks.
