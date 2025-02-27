
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score, 
        u.DisplayName AS OwnerDisplayName,
        @row_num := IF(@current_tag = p.Tags, @row_num + 1, 1) AS TagRank,
        @current_tag := p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @row_num := 0, @current_tag := '') AS vars
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY 
        p.Tags, p.Score DESC
),
TopRanked AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 3
),
PostWithComments AS (
    SELECT 
        tr.Id AS PostId, 
        tr.Title, 
        tr.CreationDate, 
        tr.ViewCount, 
        tr.Score, 
        tr.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        TopRanked tr
    LEFT JOIN 
        Comments c ON tr.Id = c.PostId
    GROUP BY 
        tr.Id, tr.Title, tr.CreationDate, tr.ViewCount, tr.Score, tr.OwnerDisplayName
),
FinalResult AS (
    SELECT 
        pwc.*, 
        @final_rank := @final_rank + 1 AS FinalRank
    FROM 
        PostWithComments pwc
    CROSS JOIN (SELECT @final_rank := 0) AS vars
    ORDER BY 
        pwc.Score DESC, pwc.CommentCount DESC
)
SELECT 
    fr.PostId, 
    fr.Title, 
    fr.CreationDate, 
    fr.ViewCount, 
    fr.Score, 
    fr.OwnerDisplayName, 
    fr.CommentCount, 
    fr.FinalRank
FROM 
    FinalResult fr
WHERE 
    fr.FinalRank <= 10
ORDER BY 
    fr.FinalRank;
