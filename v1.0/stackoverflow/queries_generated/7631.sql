WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND -- Only Questions
        p.CreationDate >= '2020-01-01' -- Posts created from 2020 onwards
    GROUP BY 
        p.Id, u.DisplayName
),
TopRankedPosts AS (
    SELECT * 
    FROM RankedPosts
    WHERE ScoreRank <= 5 -- Top 5 questions per user
)
SELECT 
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.OwnerDisplayName,
    p.CommentCount,
    ph.UserDisplayName AS LastEditor,
    ph.CreationDate AS LastEditDate
FROM 
    TopRankedPosts p
LEFT JOIN 
    PostHistory ph ON p.PostId = ph.PostId 
WHERE 
    ph.PostHistoryTypeId IN (4, 5) -- Title or Body Edit
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
