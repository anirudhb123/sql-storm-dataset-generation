
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        p.CommentCount, 
        @row_number := IF(@prev_pt_name = pt.Name, @row_number + 1, 1) AS Rank,
        @prev_pt_name := pt.Name,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @row_number := 0, @prev_pt_name := '') AS init
    WHERE 
        p.CreationDate >= '2023-10-01 12:34:56'
        AND p.ViewCount > 100
    ORDER BY 
        pt.Name, p.Score DESC, p.CreationDate DESC
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        AnswerCount, 
        CommentCount, 
        Rank, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostComments AS (
    SELECT 
        c.PostId, 
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.CreationDate, 
    tp.Score, 
    tp.ViewCount, 
    tp.AnswerCount, 
    tp.CommentCount, 
    COALESCE(pc.TotalComments, 0) AS TotalComments, 
    tp.OwnerDisplayName, 
    pb.TotalBadges
FROM 
    TopPosts tp
LEFT JOIN 
    PostComments pc ON tp.PostId = pc.PostId
LEFT JOIN 
    PostBadges pb ON tp.OwnerDisplayName = (SELECT u.DisplayName FROM Users u WHERE u.Id = pb.UserId)
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
