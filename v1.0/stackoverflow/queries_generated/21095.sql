WITH RECURSIVE TagHierarchy AS (
    SELECT 
        Id,
        TagName,
        Count,
        ExcerptPostId,
        WikiPostId,
        IsModeratorOnly,
        IsRequired,
        0 AS Level
    FROM 
        Tags 
    WHERE 
        IsModeratorOnly = 0

    UNION ALL 

    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        t.ExcerptPostId,
        t.WikiPostId,
        t.IsModeratorOnly,
        t.IsRequired,
        th.Level + 1
    FROM 
        Tags t
    JOIN 
        TagHierarchy th ON t.WikiPostId = th.Id 
    WHERE 
        th.Level < 5
),
PostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(UPPER(OwnerDisplayName), 'Unknown') AS OwnerName,
        COALESCE(Count(DISTINCT c.Id), 0) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId IN (2, 3)) AS VoteBalance
    FROM 
        Posts p 
    LEFT JOIN Comments c ON p.Id = c.PostId 
    LEFT JOIN Votes v ON p.Id = v.PostId 
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '365 days'
        AND p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, OwnerDisplayName
),
ClosedPosts AS (
    SELECT 
        Ph.PostId,
        MAX(Ph.CreationDate) AS LastClosedDate,
        COUNT(*) AS CloseReasonCount
    FROM 
        PostHistory Ph
    WHERE 
        Ph.PostHistoryTypeId IN (10, 11, 12)
    GROUP BY 
        Ph.PostId
),
PostStats AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CommentCount,
        p.OwnerName,
        p.VoteBalance,
        COALESCE(cp.LastClosedDate, 'Never') AS LastClosedDate,
        COALESCE(cp.CloseReasonCount, 0) AS CloseReasons
    FROM 
        PostInfo p
    LEFT JOIN ClosedPosts cp ON p.PostId = cp.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerName,
    ps.CommentCount,
    ps.VoteBalance,
    ps.LastClosedDate,
    ps.CloseReasons,
    STRING_AGG(DISTINCT th.TagName, ', ') AS Tags,
    SUM(CASE WHEN ps.CloseReasons > 0 THEN 1 ELSE 0 END) OVER () AS PostsWithClosures,
    CASE 
        WHEN ps.VoteBalance > 5 THEN 'Hot'
        WHEN ps.CommentCount > 10 AND ps.VoteBalance BETWEEN 1 AND 5 THEN 'Popular'
        ELSE 'Regular'
    END AS PostCategory
FROM 
    PostStats ps
LEFT JOIN 
    Tags tg ON ps.PostId = tg.ExcerptPostId
LEFT JOIN 
    TagHierarchy th ON tg.Id = th.Id
GROUP BY 
    ps.PostId, ps.Title, ps.OwnerName, ps.CommentCount, ps.VoteBalance, 
    ps.LastClosedDate, ps.CloseReasons
ORDER BY 
    ps.VoteBalance DESC, ps.CommentCount DESC 
LIMIT 100;
