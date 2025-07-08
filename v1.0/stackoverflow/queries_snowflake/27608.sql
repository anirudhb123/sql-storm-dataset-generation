
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
        ROW_NUMBER() OVER (PARTITION BY rp.Author ORDER BY rp.Score DESC) as AuthorRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.CreationDate >= DATEADD(year, -1, CAST('2024-10-01' AS DATE))
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
    LISTAGG(t.Title, '; ') as Titles,
    LISTAGG(t.Body, ' ') as AllBodies
FROM 
    TopPosts t
GROUP BY 
    t.Author
ORDER BY 
    TotalQuestions DESC
LIMIT 10;
