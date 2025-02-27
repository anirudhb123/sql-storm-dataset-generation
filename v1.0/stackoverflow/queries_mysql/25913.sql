
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        @RankByScore := IF(@PrevTag = pt.Name, @RankByScore + 1, 1) AS RankByScore,
        @PrevTag := pt.Name,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS TagList
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM 
             (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
              SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
              SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE 
             CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) t
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.LastActivityDate, p.ViewCount, p.Score, p.Tags, pt.Name
    ORDER BY 
        pt.Name, p.Score DESC
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        CreationDate, 
        LastActivityDate, 
        ViewCount, 
        Score, 
        CommentCount, 
        TagList
    FROM 
        RankedPosts 
    WHERE 
        RankByScore <= 10
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.LastActivityDate,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.TagList,
    u.DisplayName AS AuthorName,
    b.Name AS BadgeName, 
    b.Class AS BadgeClass
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.PostId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Date >= tp.CreationDate
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
