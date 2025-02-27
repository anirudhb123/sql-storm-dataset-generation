WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        OwnerDisplayName,
        AcceptedAnswerId,
        CreationDate,
        CommentCount,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        RowNum <= 5
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    CASE 
        WHEN tp.AcceptedAnswerId <> 0 THEN 'Accepted' 
        ELSE 'Not Accepted' 
    END AS AcceptanceStatus,
    COALESCE(a.Body, 'No Answer') AS AcceptedAnswerBody
FROM 
    TopPosts tp
LEFT JOIN 
    Posts a ON tp.AcceptedAnswerId = a.Id
ORDER BY 
    tp.UpVoteCount DESC, tp.CommentCount DESC
LIMIT 10;
