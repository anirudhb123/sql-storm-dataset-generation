
WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.Reputation AS OwnerReputation,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), NULL) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.Reputation
),
TopPosts AS (
    SELECT 
        ps.*,
        @row_number := IF(@prev_score = ps.Score, @row_number + 1, 1) AS Rank,
        @prev_score := ps.Score
    FROM 
        PostSummary ps,
        (SELECT @row_number := 0, @prev_score := NULL) AS vars
    ORDER BY 
        ps.Score DESC, ps.ViewCount DESC
)

SELECT 
    PostId, 
    Title, 
    CreationDate, 
    ViewCount, 
    Score,
    OwnerReputation,
    AcceptedAnswerId,
    CommentCount,
    VoteCount
FROM 
    TopPosts
WHERE 
    Rank <= 100;
