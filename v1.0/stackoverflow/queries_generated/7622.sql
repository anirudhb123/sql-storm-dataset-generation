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
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
        AND p.PostTypeId IN (1, 2)  -- Questions and Answers
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp 
    WHERE 
        rp.Rank <= 5  -- Top 5 posts per user
)
SELECT 
    tp.OwnerDisplayName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
LEFT JOIN 
    Votes v ON tp.PostId = v.PostId
LEFT JOIN 
    Badges b ON tp.OwnerDisplayName = b.UserId
GROUP BY 
    tp.OwnerDisplayName
ORDER BY 
    UpVotes DESC, DownVotes;
