WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        COUNT(a.Id) AS AnswerCount, 
        SUM(v.VoteTypeId = 2) AS UpVotes, 
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(a.Id) DESC, SUM(v.VoteTypeId = 2) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
), TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.AnswerCount, 
        rp.UpVotes, 
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    u.DisplayName AS Author, 
    tp.Title, 
    tp.CreationDate, 
    tp.AnswerCount, 
    tp.UpVotes, 
    tp.DownVotes
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerUserId = u.Id
ORDER BY 
    tp.UpVotes DESC, tp.AnswerCount DESC;
