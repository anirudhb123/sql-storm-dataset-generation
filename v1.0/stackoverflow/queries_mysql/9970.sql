
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        p.CommentCount, 
        u.DisplayName AS OwnerDisplayName,
        @row_number := IF(@prev_post_type = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_post_type := p.PostTypeId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id,
        (SELECT @row_number := 0, @prev_post_type := NULL) AS init
    WHERE 
        p.CreationDate >= '2023-10-01 12:34:56' 
        AND p.PostTypeId IN (1, 2) 
    ORDER BY 
        p.PostTypeId, p.Score DESC, p.CreationDate DESC
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
        OwnerDisplayName 
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 10
)
SELECT 
    tp.*, 
    COUNT(c.Id) AS TotalComments, 
    GROUP_CONCAT(DISTINCT tg.TagName) AS TagNames,
    COALESCE(
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2), 0
    ) AS Upvotes,
    COALESCE(
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3), 0
    ) AS Downvotes
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
LEFT JOIN 
    (SELECT pt.Id, SUBSTRING_INDEX(SUBSTRING_INDEX(pt.Tags, '><', numbers.n), '><', -1) AS TagName
     FROM 
        (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) numbers
     JOIN Posts pt ON CHAR_LENGTH(pt.Tags) -CHAR_LENGTH(REPLACE(pt.Tags, '><', '')) >= numbers.n - 1) tg ON tp.PostId = tg.Id
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.AnswerCount, tp.CommentCount, tp.OwnerDisplayName
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
