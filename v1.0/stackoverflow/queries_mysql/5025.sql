
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT TRIM(BOTH '><' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1)) AS tagArray 
         FROM Posts p 
         JOIN 
         (SELECT 1 as n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
          SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
          SELECT 9 UNION ALL SELECT 10) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1) AS tagArray ON true
    LEFT JOIN 
        Tags t ON t.TagName = tagArray
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    up.DisplayName AS User,
    COUNT(DISTINCT ph.Id) AS EditsCount,
    COUNT(DISTINCT c.Id) AS CommentsCount,
    MAX(tp.CreationDate) AS LatestPostDate,
    AVG(tp.Score) AS AverageScore,
    GROUP_CONCAT(DISTINCT tp.Tags ORDER BY tp.Tags SEPARATOR ', ') AS AllTags
FROM 
    Users up
JOIN 
    Posts p ON p.OwnerUserId = up.Id
JOIN 
    TopPosts tp ON tp.PostId = p.Id
LEFT JOIN 
    PostHistory ph ON ph.PostId = p.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
GROUP BY 
    up.DisplayName
ORDER BY 
    AverageScore DESC
LIMIT 10;
