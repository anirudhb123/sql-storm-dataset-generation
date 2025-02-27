-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(CommentsCount, 0) AS CommentsCount,
        COALESCE(VotesCount, 0) AS VotesCount,
        COALESCE(AnswersCount, 0) AS AnswersCount,
        MAX(p.HistoryDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentsCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VotesCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswersCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            MAX(CreationDate) AS HistoryDate
        FROM 
            PostHistory
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
)

SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    CommentsCount,
    VotesCount,
    AnswersCount,
    LastEditDate
FROM 
    PostStats
ORDER BY 
    ViewCount DESC
LIMIT 100;  -- Top 100 posts by view count
