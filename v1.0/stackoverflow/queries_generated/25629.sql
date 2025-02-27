WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS RankByRecency
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only select Questions
        AND p.Score > 0   -- Only select Questions with a score greater than zero
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    rp.CommentCount,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = rp.PostId) AS TotalComments,
    (SELECT STRING_AGG(DISTINCT u.DisplayName, ', ') 
     FROM Votes v 
     JOIN Users u ON v.UserId = u.Id 
     WHERE v.PostId = rp.PostId 
     AND v.VoteTypeId = 2) AS Voters,  -- Users who upvoted
    CASE 
        WHEN rp.RankByScore <= 5 THEN 'Top Score'
        WHEN rp.RankByRecency <= 5 THEN 'Recently Active'
        ELSE 'Other'
    END AS PostCategory
FROM 
    RankedPosts rp
WHERE 
    rp.RankByScore <= 10  -- Top 10 by Score
    OR rp.RankByRecency <= 10 -- Top 10 by Recency
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
