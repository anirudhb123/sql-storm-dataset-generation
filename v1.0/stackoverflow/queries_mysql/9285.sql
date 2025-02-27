
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        t.TagName,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        @row_number := IF(@current_tag = t.TagName, @row_number + 1, 1) AS Rank,
        @current_tag := t.TagName
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT ParentId, COUNT(*) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) a ON p.Id = a.ParentId
    LEFT JOIN 
        (SELECT Id, SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName 
         FROM Posts 
         CROSS JOIN (SELECT a.N + b.N * 10 AS n 
                     FROM (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
                           UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a, 
                          (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
                           UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b 
                     ORDER BY n) n 
         WHERE n.n <= (LENGTH(Tags) - LENGTH(REPLACE(Tags, '><', '')))/2) t ON p.Id = t.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @row_number := 0, @current_tag := '') r
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, c.CommentCount, a.AnswerCount, t.TagName
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, CommentCount, AnswerCount, TagName, TotalVotes,
        DENSE_RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS ScoreRank
    FROM 
        PostStatistics
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    p.AnswerCount,
    p.TagName,
    p.TotalVotes,
    CASE 
        WHEN p.ScoreRank <= 10 THEN 'Top 10 Posts'
        ELSE 'Other Posts'
    END AS PostCategory
FROM 
    TopPosts p
WHERE 
    p.ScoreRank <= 50  
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
