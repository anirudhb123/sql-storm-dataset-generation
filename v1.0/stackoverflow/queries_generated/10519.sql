-- Performance benchmarking query to analyze post activity and user engagement
WITH PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(a.AnswerCount, 0) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT 
            ParentId, 
            COUNT(*) AS AnswerCount 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId) a ON p.Id = a.ParentId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'  -- Last 30 days
    GROUP BY 
        p.Id, p.Title, p.CreationDate, a.AnswerCount
)
SELECT 
    pe.PostId,
    pe.Title,
    pe.CreationDate,
    pe.CommentCount,
    pe.VoteCount,
    pe.UpVotes,
    pe.DownVotes,
    pe.AnswerCount,
    CASE WHEN pe.VoteCount > 0 THEN ROUND((pe.UpVotes::decimal / pe.VoteCount) * 100, 2) ELSE 0 END AS UpVotePercentage
FROM 
    PostEngagement pe
ORDER BY 
    pe.VoteCount DESC, pe.CreationDate DESC;
