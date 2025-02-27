-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(au.UpVotes, 0) AS UpVotes,
        COALESCE(au.DownVotes, 0) AS DownVotes,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(answers.AnswerCount, 0) AS AnswerCount,
        p.CreationDate
    FROM 
        Posts p
    LEFT JOIN 
        (
            SELECT 
                OwnerUserId, 
                SUM(UpVotes) AS UpVotes, 
                SUM(DownVotes) AS DownVotes 
            FROM 
                Users 
            GROUP BY 
                OwnerUserId
        ) au ON p.OwnerUserId = au.OwnerUserId
    LEFT JOIN 
        (
            SELECT 
                PostId, 
                COUNT(*) AS CommentCount 
            FROM 
                Comments 
            GROUP BY 
                PostId
        ) c ON p.Id = c.PostId
    LEFT JOIN 
        (
            SELECT 
                ParentId, 
                COUNT(*) AS AnswerCount 
            FROM 
                Posts 
            WHERE 
                PostTypeId = 2 
            GROUP BY 
                ParentId
        ) answers ON p.Id = answers.ParentId
    WHERE 
        p.PostTypeId = 1
)
SELECT 
    Id,
    Title,
    Score,
    ViewCount,
    UpVotes,
    DownVotes,
    CommentCount,
    AnswerCount,
    CreationDate
FROM 
    PostStats
ORDER BY 
    Score DESC, 
    ViewCount DESC 
LIMIT 100;
