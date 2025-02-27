WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByTag
    FROM 
        Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.OwnerName, 
        rp.CreationDate, 
        rp.Score, 
        rp.CommentCount, 
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByTag <= 5
)
SELECT 
    tp.Title,
    tp.OwnerName,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.AnswerCount,
    COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY tp.PostId), 0) AS TotalUpVotes,
    COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY tp.PostId), 0) AS TotalDownVotes
FROM 
    TopPosts tp
LEFT JOIN Votes v ON tp.PostId = v.PostId
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC;
