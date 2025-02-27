
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.ViewCount,
        tp.Score,
        tp.AnswerCount,
        tp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.ViewCount, tp.Score, tp.AnswerCount, tp.OwnerDisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    (ps.UpVotes - ps.DownVotes) AS NetVotes
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
