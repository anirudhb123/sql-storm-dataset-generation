WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- From the last year
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Author,
        ViewCount,
        Score
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10 -- Top 10 questions per user
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Body,
        tp.CreationDate,
        tp.Author,
        tp.ViewCount,
        tp.Score,
        COALESCE(json_agg(c.Text) FILTER (WHERE c.Text IS NOT NULL), '[]') AS Comments,
        COALESCE(json_agg(DISTINCT pt.Name) FILTER (WHERE pt.Name IS NOT NULL), '[]') AS PostTypes,
        COALESCE(json_agg(DISTINCT bt.Name) FILTER (WHERE bt.Name IS NOT NULL), '[]') AS Badges
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    LEFT JOIN 
        Badges b ON b.UserId = tp.Author -- Assuming Author’s UserId refers here
    LEFT JOIN 
        PostTypes pt ON pt.Id = v.VoteTypeId
    GROUP BY 
        tp.PostId, tp.Title, tp.Body, tp.CreationDate, tp.Author, tp.ViewCount, tp.Score
)
SELECT 
    PostId,
    Title,
    Body,
    CreationDate,
    Author,
    ViewCount,
    Score,
    Comments,
    PostTypes,
    Badges
FROM 
    PostDetails
ORDER BY 
    Score DESC, 
    ViewCount DESC;
