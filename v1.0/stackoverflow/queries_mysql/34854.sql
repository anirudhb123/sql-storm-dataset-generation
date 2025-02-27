
WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.AnswerCount,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        @row_number := IF(@prev_owner = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @prev_owner := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    CROSS JOIN (SELECT @row_number := 0, @prev_owner := NULL) AS vars
    GROUP BY 
        p.Id, p.Title, p.AnswerCount, p.ViewCount, p.CreationDate, p.Score, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        *,
        CASE 
            WHEN Score > 10 THEN 'High Score'
            WHEN Score BETWEEN 5 AND 10 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RecursivePostCTE
    WHERE 
        CreationDate > DATE_SUB('2024-10-01', INTERVAL 1 YEAR)
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalResults AS (
    SELECT 
        fp.Title,
        fp.ViewCount,
        fp.AnswerCount,
        fp.TotalBounty,
        fp.Score,
        fp.ScoreCategory,
        COALESCE(pc.CommentCount, 0) AS CommentCount
    FROM 
        FilteredPosts fp
    LEFT JOIN PostComments pc ON fp.PostId = pc.PostId
    WHERE 
        fp.ScoreCategory <> 'Low Score'
)
SELECT 
    fr.Title,
    fr.ViewCount,
    fr.AnswerCount,
    fr.TotalBounty,
    fr.Score,
    fr.ScoreCategory,
    fr.CommentCount,
    @final_rank := @final_rank + 1 AS FinalRank
FROM 
    FinalResults fr
CROSS JOIN (SELECT @final_rank := 0) AS vars
WHERE 
    fr.CommentCount > 5
ORDER BY 
    fr.Score ASC, fr.ViewCount DESC;
