
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate > '2022-01-01' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, u.Reputation
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        CommentCount,
        VoteCount,
        OwnerDisplayName,
        OwnerReputation,
        @row_number := IF(@prev_score = Score, @row_number, 0) + 1 AS Ranking,
        @prev_score := Score
    FROM 
        PostStats, (SELECT @row_number := 0, @prev_score := NULL) AS vars
    ORDER BY 
        Score DESC
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    CommentCount,
    VoteCount,
    OwnerDisplayName,
    OwnerReputation
FROM 
    TopPosts
WHERE 
    Ranking <= 10;
