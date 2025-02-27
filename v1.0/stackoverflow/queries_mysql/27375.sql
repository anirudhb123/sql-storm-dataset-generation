
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tag_name
         FROM Posts p 
         INNER JOIN (SELECT 1 as n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                     UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
         ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        UPPER(u.DisplayName) AS DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.Tags,
        @rank := @rank + 1 AS PostRank
    FROM 
        RankedPosts rp, (SELECT @rank := 0) r
    ORDER BY 
        rp.Score DESC, rp.ViewCount DESC
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount,
    tp.Tags,
    ua.DisplayName,
    ua.QuestionCount,
    ua.TotalViews,
    ua.TotalScore
FROM 
    TopPosts tp
JOIN 
    UserActivity ua ON ua.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId LIMIT 1)
WHERE 
    tp.PostRank <= 10  
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
