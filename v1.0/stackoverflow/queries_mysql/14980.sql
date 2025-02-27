
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.BadgeCount,
    @viewRank := IF(@prevViewCount = rp.ViewCount, @viewRank, @rank := @rank + 1) AS ViewRank,
    @prevViewCount := rp.ViewCount,
    @scoreRank := IF(@prevScore = rp.Score, @scoreRank, @rankScore := @rankScore + 1) AS ScoreRank,
    @prevScore := rp.Score
FROM 
    RankedPosts rp,
    (SELECT @viewRank := 0, @prevViewCount := NULL, @rank := 0, @scoreRank := 0, @prevScore := NULL) AS vars
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC;
