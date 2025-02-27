WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId IN (2)) FILTER (WHERE v.VoteTypeId = 2), 0) AS UpvoteCount,
        COALESCE(SUM(v.VoteTypeId IN (3)) FILTER (WHERE v.VoteTypeId = 3), 0) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount,
        (rp.UpvoteCount - rp.DownvoteCount) AS NetVotes,
        CASE 
            WHEN rp.ViewRank <= 5 THEN 'Top 5 Posts'
            WHEN rp.ViewCount > 50 THEN 'Popular Post'
            ELSE 'Regular Post' 
        END AS PostCategory,
        NULLIF(rp.ViewCount, 0) AS NonZeroViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.ViewRank <= 10
),
PostLinkSnippets AS (
    SELECT 
        pl.PostId,
        STRING_AGG(CONCAT('Related to Post ID: ', pl.RelatedPostId), '; ') AS RelatedPosts
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ps.NetVotes,
    ps.PostCategory,
    pls.RelatedPosts,
    CASE 
        WHEN ps.NonZeroViewCount IS NOT NULL THEN ROUND(CAST(ps.ViewCount AS DECIMAL) / ps.NonZeroViewCount, 2)
        ELSE 0 
    END AS ViewCountRatio,
    CASE 
        WHEN ps.PostCategory = 'Top 5 Posts' AND ps.NetVotes > 0 THEN 'Featured Post'
        ELSE 'Standard Post'
    END AS FeaturedStatus,
    (SELECT 
        COUNT(*) 
     FROM 
        Posts p 
     WHERE 
        p.AcceptedAnswerId = ps.PostId
    ) AS AcceptedAnswerCount
FROM 
    PostStatistics ps
LEFT JOIN 
    PostLinkSnippets pls ON ps.PostId = pls.PostId
ORDER BY 
    ps.ViewCount DESC, ps.CommentCount DESC;
