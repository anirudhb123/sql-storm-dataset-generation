WITH RECURSIVE PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.AcceptedAnswerId,
        pp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PopularPosts pp ON p.ParentId = pp.PostId 
    WHERE 
        p.PostTypeId = 2 -- Answers
),
PostDetails AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetVotes,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (ORDER BY COUNT(c.Id) DESC) AS RankByComments
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts from the last year
    GROUP BY 
        p.Id, p.Title
),
ExternalPostLinks AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
),
WithLinkCounts AS (
    SELECT 
        pd.Id,
        pd.Title,
        pd.NetVotes,
        pd.CommentCount,
        ISNULL(epl.RelatedPostCount, 0) AS RelatedPostCount,
        pd.RankByComments
    FROM 
        PostDetails pd
    LEFT JOIN 
        ExternalPostLinks epl ON pd.Id = epl.PostId
)
SELECT 
    wlc.Id,
    wlc.Title,
    wlc.NetVotes,
    wlc.CommentCount,
    wlc.RelatedPostCount,
    CASE 
        WHEN wlc.CommentCount > 50 THEN 'Hot'
        WHEN wlc.CommentCount BETWEEN 20 AND 50 THEN 'Trending'
        ELSE 'Normal'
    END AS PopularityStatus,
    COALESCE(pp.ViewCount, 0) AS TotalViews
FROM 
    WithLinkCounts wlc
LEFT JOIN 
    PopularPosts pp ON wlc.Id = pp.PostId
WHERE 
    pp.Level IS NOT NULL OR wlc.CommentCount > 0
ORDER BY 
    wlc.NetVotes DESC, 
    wlc.RankByComments ASC,
    wlc.RelatedPostCount DESC;

