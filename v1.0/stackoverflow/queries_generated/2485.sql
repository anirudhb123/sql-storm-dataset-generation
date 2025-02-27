WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Assuming 8 = BountyStart, 9 = BountyClose
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    ps.CommentCount,
    ps.TotalBounty,
    CASE 
        WHEN ps.TotalBounty > 0 THEN 'Has Bounty'
        ELSE 'No Bounty'
    END AS BountyStatus
FROM 
    TopPosts tp
LEFT JOIN 
    PostStats ps ON tp.Id = ps.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
LIMIT 10;

-- Find unanswered questions with >3 comments
SELECT 
    p.Id,
    p.Title,
    p.CreationDate,
    COALESCE(a.AnswerCount, 0) AS AnswerCount,
    c.CommentCount
FROM 
    Posts p
LEFT JOIN 
    (SELECT ParentId, COUNT(Id) AS AnswerCount
     FROM Posts 
     WHERE PostTypeId = 2
     GROUP BY ParentId) a ON p.Id = a.ParentId
JOIN 
    (SELECT PostId, COUNT(Id) AS CommentCount
     FROM Comments 
     GROUP BY PostId HAVING COUNT(Id) > 3) c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1 AND 
    p.AcceptedAnswerId IS NULL
ORDER BY 
    c.CommentCount DESC;
