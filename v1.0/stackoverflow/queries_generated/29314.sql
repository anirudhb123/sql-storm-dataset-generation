WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        COALESCE(cc.CommentCount, 0) AS CommentCount,
        COALESCE(ba.BadgeCount, 0) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) cc ON p.Id = cc.PostId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) ba ON u.Id = ba.UserId
    WHERE 
        p.PostTypeId IN (1, 2) -- Considering only questions and answers
    AND 
        p.Score > 0 -- Only considering posts with a positive score
), FilteredPosts AS (
    SELECT 
        rp.*
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 AND -- Top 10 ranked posts in each post type
        rp.BadgeCount > 2 -- Users with more than 2 badges
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Tags,
    fp.OwnerDisplayName,
    TO_CHAR(fp.CreationDate, 'YYYY-MM-DD HH24:MI:SS') AS FormattedCreationDate,
    fp.Score,
    fp.CommentCount
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.CreationDate ASC; -- Order by score and then by creation date
