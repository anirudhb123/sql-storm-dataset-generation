
WITH RankedPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName as Author,
        COUNT(c.Id) as CommentCount,
        AVG(v.VoteTypeId) as AverageVoteType
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.*,
        @row_number := IF(@current_author = rp.Author, @row_number + 1, 1) as AuthorRank,
        @current_author := rp.Author
    FROM 
        RankedPosts rp, (SELECT @row_number := 0, @current_author := '') as init
    WHERE 
        rp.CreationDate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
    ORDER BY 
        rp.Author, rp.Score DESC
),
TopPosts AS (
    SELECT 
        fp.*
    FROM 
        FilteredPosts fp
    WHERE 
        fp.AuthorRank <= 5 
)

SELECT 
    t.Author,
    COUNT(t.PostId) as TotalQuestions,
    SUM(t.CommentCount) as TotalComments,
    ROUND(AVG(t.AverageVoteType), 2) as AvgVoteType,
    GROUP_CONCAT(t.Title SEPARATOR '; ') as Titles,
    GROUP_CONCAT(t.Body SEPARATOR ' ') as AllBodies
FROM 
    TopPosts t
GROUP BY 
    t.Author
ORDER BY 
    TotalQuestions DESC
LIMIT 10;
