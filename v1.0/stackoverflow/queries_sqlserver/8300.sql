
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RN = 1
    ORDER BY 
        rp.UpvoteCount - rp.DownvoteCount DESC 
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.UpvoteCount,
    tp.DownvoteCount,
    CASE 
        WHEN tp.UpvoteCount > tp.DownvoteCount THEN 'Positive'
        WHEN tp.UpvoteCount < tp.DownvoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerDisplayName = u.DisplayName
WHERE 
    u.Reputation > 1000 
ORDER BY 
    tp.CreationDate DESC;
