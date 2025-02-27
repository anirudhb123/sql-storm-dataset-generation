
WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        p.AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, p.AnswerCount
),
PopularPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        VoteCount,
        AnswerCount,
        @row_number := IF(@prev_view_count = ViewCount, @row_number, @row_number + 1) AS ViewRank,
        @prev_view_count := ViewCount
    FROM 
        PostSummary,
        (SELECT @row_number := 0, @prev_view_count := NULL) AS vars
    ORDER BY 
        ViewCount DESC
)

SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    OwnerDisplayName,
    CommentCount,
    VoteCount,
    AnswerCount
FROM 
    PopularPosts
WHERE 
    ViewRank <= 10;
