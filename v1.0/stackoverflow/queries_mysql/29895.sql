
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '>', '')) + 1) AS TagCount,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS Upvotes,
        @RecentPostRank := IF(@ptName = pt.Name, @RecentPostRank + 1, 1) AS RecentPostRank,
        @TopScoreRank := IF(@ptName = pt.Name AND @prevScore > p.Score, @TopScoreRank + 1, 1) AS TopScoreRank,
        @ptName := pt.Name,
        @prevScore := p.Score,
        pt.Id AS PostTypeId
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id,
        (SELECT @RecentPostRank := 0, @TopScoreRank := 0, @ptName := '', @prevScore := NULL) AS vars
    WHERE 
        p.CreationDate >= '2023-10-01 12:34:56'
    ORDER BY 
        pt.Name, p.CreationDate DESC, p.Score DESC
)
SELECT 
    rpt.PostId,
    rpt.Title,
    rpt.CreationDate,
    rpt.TagCount,
    rpt.CommentCount,
    rpt.Upvotes,
    pt.Name AS PostType,
    CASE 
        WHEN rpt.RecentPostRank = 1 THEN 'Most Recent'
        WHEN rpt.TopScoreRank = 1 THEN 'Top Scoring'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts rpt
JOIN 
    PostTypes pt ON rpt.PostTypeId = pt.Id
WHERE 
    rpt.TagCount > 2
GROUP BY 
    rpt.PostId, rpt.Title, rpt.CreationDate, rpt.TagCount, rpt.CommentCount, rpt.Upvotes, pt.Name, rpt.RecentPostRank, rpt.TopScoreRank
ORDER BY 
    rpt.Upvotes DESC, rpt.CommentCount DESC
LIMIT 10;
