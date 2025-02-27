
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        @row_number := IF(@current_partition = pt.Name, @row_number + 1, 1) AS Rank,
        @current_partition := pt.Name,
        u.DisplayName AS OwnerDisplayName,
        GROUP_CONCAT(DISTINCT t.TagName) AS TagsList
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', numbers.n), '<>', -1)) AS tag
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '<>', '')) >= numbers.n - 1) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag = t.TagName,
        (SELECT @row_number := 0, @current_partition := '') AS vars
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL 1 YEAR 
    GROUP BY 
        p.Id, pt.Name, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        *,
        (SELECT COUNT(*) FROM RankedPosts rp WHERE rp.Rank <= 5 AND rp.Name = RankedPosts.Name) AS TotalPosts 
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    FavoriteCount,
    OwnerDisplayName,
    TagsList,
    TotalPosts
FROM 
    TopRankedPosts
ORDER BY 
    TotalPosts DESC, Score DESC;
