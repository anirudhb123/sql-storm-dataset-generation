WITH RecursivePostLinks AS (
    SELECT 
        pl.Id,
        pl.PostId,
        pl.RelatedPostId,
        1 AS LinkDepth
    FROM 
        PostLinks pl
    WHERE 
        pl.PostId IS NOT NULL

    UNION ALL

    SELECT 
        pl.Id,
        pl.PostId,
        pl.RelatedPostId,
        rpl.LinkDepth + 1
    FROM 
        PostLinks pl
    INNER JOIN 
        RecursivePostLinks rpl ON pl.RelatedPostId = rpl.PostId
),
AggregatedVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
EnhancedPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(a.UpVotes, 0) AS UpVotes,
        COALESCE(a.DownVotes, 0) AS DownVotes,
        COALESCE(a.TotalVotes, 0) AS TotalVotes,
        COUNT(c.Id) AS CommentCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        AggregatedVotes a ON p.Id = a.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, a.UpVotes, a.DownVotes, a.TotalVotes
),
TopPosts AS (
    SELECT 
        eps.PostId,
        eps.Title,
        eps.ViewCount,
        eps.UpVotes,
        eps.DownVotes,
        eps.TotalVotes,
        eps.CommentCount,
        ROW_NUMBER() OVER (ORDER BY eps.TotalVotes DESC, eps.ViewCount DESC) AS Rank
    FROM 
        EnhancedPostStats eps
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.UpVotes,
    pp.DownVotes,
    pp.TotalVotes,
    pp.CommentCount,
    pl.RelatedPostId,
    pl.LinkDepth,
    CASE WHEN pp.CommentCount > 0 THEN 'Has Comments' ELSE 'No Comments' END AS CommentStatus,
    CASE WHEN pp.UpVotes - pp.DownVotes > 10 THEN 'Highly Voted' ELSE 'Less Popular' END AS PopularityStatus
FROM 
    TopPosts pp
LEFT JOIN 
    RecursivePostLinks pl ON pp.PostId = pl.PostId
WHERE 
    pp.Rank <= 10
ORDER BY 
    pp.Rank;
