
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        @row_number := IF(@current_user_id = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @current_user_id := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    CROSS JOIN 
        (SELECT @row_number := 0, @current_user_id := NULL) AS vars
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.Tags, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.*,
        @global_rank := @global_rank + 1 AS GlobalRank
    FROM 
        RankedPosts rp
    CROSS JOIN 
        (SELECT @global_rank := 0) AS vars
    WHERE 
        rp.Rank <= 5 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.Tags,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.AnswerCount,
    fp.GlobalRank
FROM 
    FilteredPosts fp
WHERE 
    fp.GlobalRank <= 20
ORDER BY 
    fp.GlobalRank;
