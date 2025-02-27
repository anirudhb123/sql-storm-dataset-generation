
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        LEN(REPLACE(p.Tags, '>', '')) + 1 AS TagCount,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS Upvotes,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS RecentPostRank,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS TopScoreRank,
        pt.Id AS PostTypeId
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
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
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
