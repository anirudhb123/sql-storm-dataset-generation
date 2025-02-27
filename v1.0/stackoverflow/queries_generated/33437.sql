WITH RecursivePostLinks AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        1 AS LinkLevel
    FROM 
        PostLinks pl
    WHERE 
        pl.PostId IS NOT NULL
    
    UNION ALL
    
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        rpl.LinkLevel + 1
    FROM 
        PostLinks pl
    JOIN 
        RecursivePostLinks rpl ON pl.PostId = rpl.RelatedPostId
),
PostRankings AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedCount
    FROM 
        Posts p
    LEFT JOIN 
        RecursivePostLinks rpl ON p.Id = rpl.PostId
    GROUP BY 
        p.Id
),
BadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PopularPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id
    HAVING 
        COUNT(c.Id) > 5
),
FinalResults AS (
    SELECT 
        pu.DisplayName,
        pp.Title,
        pp.Score,
        pp.ViewCount,
        pp.CommentCount,
        pu.GoldBadges,
        pu.SilverBadges,
        pu.BronzeBadges,
        pr.RelatedCount
    FROM 
        PopularPosts pp
    JOIN 
        Users pu ON pp.PostID IN (SELECT DISTINCT p.Id FROM Posts p WHERE p.OwnerUserId = pu.Id)
    JOIN 
        PostRankings pr ON pp.PostID = pr.PostID
    JOIN 
        BadgedUsers bu ON pu.Id = bu.UserId
)

SELECT 
    *
FROM 
    FinalResults
WHERE 
    (GoldBadges > 0 OR SilverBadges > 0 OR BronzeBadges > 0)
ORDER BY 
    Score DESC, ViewCount DESC;

This query involves several advanced SQL features including:

1. A recursive CTE to gather related posts, allowing the analysis of post relationships.
2. Ranking posts by score using the `ROW_NUMBER()` window function.
3. Aggregate functions to count distinct related posts and comments.
4. Conditional aggregation for counting badges based on their class.
5. Filtering for popular posts based on recent activity and comment count.
6. Final results that combine multiple pieces of information in a meaningful way, underscoring performance benchmarking opportunities based on user engagement and post statistics.
