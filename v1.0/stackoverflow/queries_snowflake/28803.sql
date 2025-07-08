
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        LISTAGG(t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        LATERAL SPLIT_TO_TABLE(SUBSTR(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '30 days' 
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
    DATEDIFF(DAY, tq.CreationDate, CAST('2024-10-01 12:34:56' AS TIMESTAMP)) AS DaysSincePosted,
    (SELECT 
         COUNT(*) 
     FROM 
         Comments c 
     WHERE 
         c.PostId = tq.PostId) AS CommentCount,
    (SELECT 
         LISTAGG(b.Name, ', ') 
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
