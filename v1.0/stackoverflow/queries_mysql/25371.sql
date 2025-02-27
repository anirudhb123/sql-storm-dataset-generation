
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > CURDATE() - INTERVAL 1 YEAR 
        AND pt.Name = 'Question'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.Tags, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Tags,
        rp.OwnerName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)

SELECT 
    fp.Title,
    LEFT(fp.Body, 200) AS ShortBody,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.OwnerName,
    fp.CommentCount,
    GROUP_CONCAT(t.TagName SEPARATOR ', ') AS TagsList
FROM 
    FilteredPosts fp
LEFT JOIN 
    (SELECT 
         Id, 
         SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName
     FROM 
         Posts
     JOIN 
         (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1) t ON t.Id = fp.PostId
GROUP BY 
    fp.PostId, fp.Title, fp.Body, fp.CreationDate, fp.ViewCount, fp.Score, fp.OwnerName, fp.CommentCount
ORDER BY 
    fp.Score DESC;
