
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, OwnerDisplayName
),
PopularPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount, 
        AnswerCount, 
        CommentCount, 
        UpVoteCount, 
        DownVoteCount,
        @rank := IF(@prev_score = Score, @rank, @rank + 1) AS Rank,
        @prev_score := Score
    FROM 
        PostMetrics, (SELECT @rank := 0, @prev_score := NULL) r
    ORDER BY 
        Score DESC, ViewCount DESC
)
SELECT 
    PostId, 
    Title, 
    Score, 
    ViewCount, 
    AnswerCount, 
    CommentCount, 
    UpVoteCount, 
    DownVoteCount,
    Rank
FROM 
    PopularPosts
WHERE 
    Rank <= 10;
