-- Performance benchmarking query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.Reputation AS OwnerReputation,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > '2020-01-01' -- Filter for posts created after a specific date
    GROUP BY 
        p.Id, u.Reputation
),
Benchmark AS (
    SELECT
        PostTypeId,
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore,
        AVG(AnswerCount) AS AvgAnswerCount,
        AVG(CommentCount) AS AvgCommentCount,
        AVG(FavoriteCount) AS AvgFavoriteCount,
        AVG(OwnerReputation) AS AvgOwnerReputation,
        COUNT(PostId) AS TotalPosts
    FROM 
        PostStats
    GROUP BY 
        PostTypeId
)
SELECT 
    ptt.Name AS PostType,
    b.AvgViewCount,
    b.AvgScore,
    b.AvgAnswerCount,
    b.AvgCommentCount,
    b.AvgFavoriteCount,
    b.AvgOwnerReputation,
    b.TotalPosts
FROM 
    Benchmark b
JOIN 
    PostTypes ptt ON b.PostTypeId = ptt.Id
ORDER BY 
    b.AvgViewCount DESC; -- Ordering by average view count
