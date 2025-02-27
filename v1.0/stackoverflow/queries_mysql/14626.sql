
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        COALESCE((SELECT COUNT(a.Id) FROM Posts a WHERE a.AcceptedAnswerId = p.Id), 0) AS AcceptedAnswers
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', n.n), '<>', -1) AS TagName, p.Id 
         FROM Posts p CROSS JOIN 
         (SELECT @row := @row + 1 AS n FROM 
          (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
           UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) t1, 
          (SELECT @row := 0) t2) n 
         WHERE n.n <= LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '<>', '')) + 1) AS t ON p.Id = t.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
)

SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    CommentCount,
    VoteCount,
    Tags,
    AcceptedAnswers
FROM 
    PostStats
ORDER BY 
    Score DESC, ViewCount DESC;
