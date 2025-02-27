
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        pgnt.Rank,
        @row_number := IF(@prev_post_type_id = p.PostTypeId, @row_number + 1, 1) AS RowNum,
        @prev_post_type_id := p.PostTypeId,
        CASE 
            WHEN p.Score > 0 THEN 'Positive'
            WHEN p.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreCategory,
        COALESCE(NULLIF(SUBSTRING(p.Body, 1, 100), ''), 'No Content') AS ShortBody
    FROM 
        Posts p,
        (SELECT @row_number := 0, @prev_post_type_id := NULL) AS vars
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentsCount,
            SUM(Score) AS CommentsScore
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            Id,
            @rank := @rank + 1 AS Rank
        FROM 
            (SELECT Id FROM Posts ORDER BY CreationDate DESC) AS ranked_posts,
            (SELECT @rank := 0) AS ranks
    ) pgnt ON p.Id = pgnt.Id
    WHERE 
        p.ViewCount > (SELECT AVG(ViewCount) FROM Posts) 
        AND (p.CreationDate > DATE_SUB('2024-10-01', INTERVAL 1 YEAR))
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ShortBody,
    rp.Score,
    rp.ScoreCategory,
    rp.CreationDate,
    COALESCE(c.CommentsCount, 0) AS TotalComments,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotesCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotesCount,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = rp.PostId AND ph.PostHistoryTypeId = 10) AS CloseVotesCount,
    CASE 
        WHEN rp.RowNum = 1 THEN 'Most Recent Post'
        ELSE NULL 
    END AS PostFlag
FROM 
    RankedPosts rp
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentsCount FROM Comments GROUP BY PostId) c ON rp.PostId = c.PostId
WHERE 
    EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId IN (1, 2)) 
ORDER BY 
    rp.Rank, rp.Score DESC
LIMIT 50;
