
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Body,
        u.DisplayName AS AuthorDisplayName,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName
         FROM 
           (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
            UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
         WHERE 
           CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tag_list ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_list.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.ViewCount, p.Score
),
MostLikedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.Score,
        pd.Tags,
        pd.AnswerCount,
        pd.CommentCount,
        @rank_by_score := IF(pd.Score IS NOT NULL, @rank_by_score + 1, @rank_by_score) AS RankByScore,
        @rank_by_views := IF(pd.ViewCount IS NOT NULL, @rank_by_views + 1, @rank_by_views) AS RankByViews
    FROM 
        PostDetails pd, (SELECT @rank_by_score := 0, @rank_by_views := 0) r
    ORDER BY pd.Score DESC, pd.ViewCount DESC
)
SELECT 
    mlp.PostId,
    mlp.Title,
    mlp.CreationDate,
    mlp.ViewCount,
    mlp.Score,
    mlp.Tags,
    mlp.AnswerCount,
    mlp.CommentCount,
    CASE 
        WHEN mlp.RankByScore <= 10 THEN 'Top Scored'
        WHEN mlp.RankByViews <= 10 THEN 'Top Viewed'
        ELSE 'Other'
    END AS PostCategory
FROM 
    MostLikedPosts mlp
WHERE 
    mlp.RankByScore <= 10 OR mlp.RankByViews <= 10
ORDER BY 
    mlp.Score DESC, mlp.ViewCount DESC;
