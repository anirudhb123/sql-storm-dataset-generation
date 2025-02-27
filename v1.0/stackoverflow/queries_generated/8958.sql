WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS TotalComments,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS Upvotes, 
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.TotalComments,
        rp.Upvotes,
        rp.Downvotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.TotalComments,
    tp.Upvotes,
    tp.Downvotes,
    (tp.Upvotes - tp.Downvotes) AS NetVotes
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
WHERE 
    u.Reputation > 1000
ORDER BY 
    NetVotes DESC, tp.TotalComments DESC;
