
WITH BenchmarkData AS (
    SELECT 
        p.Id AS PostId,
        p.CreationDate AS PostCreationDate,
        p.Score AS PostScore,
        p.ViewCount AS PostViewCount,
        p.AnswerCount AS PostAnswerCount,
        p.CommentCount AS PostCommentCount,
        u.Reputation AS UserReputation,
        u.CreationDate AS UserCreationDate,
        COUNT(c.Id) AS CommentCountByPost,
        COUNT(b.Id) AS BadgeCountByUser
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, u.Reputation, u.CreationDate
)
SELECT 
    PostId,
    PostCreationDate,
    PostScore,
    PostViewCount,
    PostAnswerCount,
    PostCommentCount,
    UserReputation,
    UserCreationDate,
    CommentCountByPost,
    BadgeCountByUser
FROM 
    BenchmarkData
ORDER BY 
    PostScore DESC, PostViewCount DESC
LIMIT 100;
