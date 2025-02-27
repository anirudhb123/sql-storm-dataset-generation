WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Selecting only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Questions created in the last year
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 -- Top 5 questions per user
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
MaxComments AS (
    SELECT 
        pc.PostId,
        pc.CommentCount,
        ROW_NUMBER() OVER (ORDER BY pc.CommentCount DESC) AS CommentRank
    FROM 
        PostComments pc
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    mc.CommentCount
FROM 
    TopPosts tp
LEFT JOIN 
    MaxComments mc ON tp.PostId = mc.PostId
WHERE 
    mc.CommentRank <= 5 -- Including top 5 most commented posts
ORDER BY 
    tp.CreationDate DESC;
