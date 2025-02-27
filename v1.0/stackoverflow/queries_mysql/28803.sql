
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        GROUP_CONCAT(t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS TagName
         FROM 
         (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
          SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
          SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag.TagName
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY) 
    GROUP BY 
        p.Id, p.Title, p.Body, p.ViewCount, p.CreationDate, pt.Name
), 
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tq.PostId,
    tq.Title,
    tq.ViewCount,
    DATEDIFF('2024-10-01 12:34:56', tq.CreationDate) AS DaysSincePosted,
    (SELECT 
         COUNT(*) 
     FROM 
         Comments c 
     WHERE 
         c.PostId = tq.PostId) AS CommentCount,
    (SELECT 
         GROUP_CONCAT(b.Name ORDER BY b.Name SEPARATOR ', ') 
     FROM 
         Badges b 
     JOIN 
         Users u ON b.UserId = u.Id 
     WHERE 
         u.Id IN (SELECT OwnerUserId FROM Posts WHERE Id = tq.PostId)) AS BadgeWinners
FROM 
    TopQuestions tq
ORDER BY 
    tq.ViewCount DESC, 
    tq.CreationDate DESC;
