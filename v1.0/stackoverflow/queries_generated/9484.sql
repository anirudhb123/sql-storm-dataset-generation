WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreatedDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
        AND p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreatedDate, p.Score, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreatedDate,
        rp.Score,
        rp.CommentCount,
        rp.AnswerCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    t.PostId,
    t.Title,
    t.CreatedDate,
    t.Score,
    t.CommentCount,
    t.AnswerCount,
    t.UpVotes,
    t.DownVotes,
    u.DisplayName,
    u.Reputation
FROM 
    TopPosts t
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = t.PostId)
ORDER BY 
    t.Score DESC, t.CreatedDate DESC
LIMIT 10;
