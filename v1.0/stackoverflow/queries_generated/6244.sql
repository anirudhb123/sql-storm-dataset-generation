WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        MAX(ph.CreationDate) AS LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(a.Id) DESC, SUM(v.VoteTypeId = 2) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.AnswerCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.LastEditDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    u.DisplayName,
    u.Reputation,
    tp.Title,
    tp.AnswerCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.LastEditDate
FROM 
    Users u
JOIN 
    TopPosts tp ON u.Id = tp.PostId
ORDER BY 
    u.Reputation DESC, tp.UpVotes DESC;
