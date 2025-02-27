WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND -- Only Questions
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Last year
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        *
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 3 -- Top 3 per user
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.Upvotes,
    tp.Downvotes,
    COALESCE(b.Name, 'No Badge') AS BadgeName
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON tp.OwnerUserId = b.UserId
WHERE 
    b.Date >= NOW() - INTERVAL '6 months' -- Recent badges
ORDER BY 
    tp.Score DESC, tp.CreationDate ASC;
