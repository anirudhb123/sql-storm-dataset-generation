
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        @row_number := IF(@prev_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @prev_owner_user_id := p.OwnerUserId,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id,
        (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS vars
    WHERE 
        p.ViewCount > 1000
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
), 
PostComments AS (
    SELECT 
        pc.PostId,
        COUNT(pc.Id) AS CommentCount,
        GROUP_CONCAT(pc.Text SEPARATOR '; ') AS Comments
    FROM 
        Comments pc
    GROUP BY 
        pc.PostId
), 
PostsWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        rp.OwnerUserId
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT 
            UserId, 
            COUNT(Id) AS BadgeCount 
         FROM 
            Badges 
         WHERE 
            Class = 1 /* Gold badges */
         GROUP BY 
            UserId) b ON rp.OwnerUserId = b.UserId
), 
FinalResults AS (
    SELECT 
        pwb.Title,
        pwb.ViewCount,
        pwb.Score,
        pwb.BadgeCount,
        pc.CommentCount,
        pc.Comments,
        pwb.CreationDate
    FROM 
        PostsWithBadges pwb
    LEFT JOIN 
        PostComments pc ON pwb.PostId = pc.PostId
)
SELECT 
    f.Title,
    f.ViewCount,
    f.Score,
    f.BadgeCount,
    f.CommentCount,
    f.Comments,
    (SELECT COUNT(*) 
     FROM FinalResults f2 
     WHERE f2.Score > f.Score OR (f2.Score = f.Score AND f2.ViewCount > f.ViewCount)) + 1 AS RankScore
FROM 
    FinalResults f
WHERE 
    f.BadgeCount > 0 OR f.CommentCount > 5
ORDER BY 
    RankScore,
    f.CreationDate DESC
LIMIT 100;
