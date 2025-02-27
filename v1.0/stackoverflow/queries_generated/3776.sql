WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.ViewCount
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        u.Reputation,
        p.ViewCount,
        p.CommentCount,
        p.UpVotes,
        p.DownVotes
    FROM 
        RankedPosts p
    INNER JOIN 
        UserReputation u ON u.UserId = p.OwnerUserId
    WHERE 
        p.rn = 1 -- Getting only the most recent post per user
)
SELECT 
    t.Title,
    t.Reputation,
    t.ViewCount,
    t.CommentCount,
    t.UpVotes,
    t.DownVotes,
    (t.UpVotes - t.DownVotes) AS NetVotes
FROM 
    TopPosts t
ORDER BY 
    t.Reputation DESC, t.ViewCount DESC 
LIMIT 10;

-- Bonus: A union with posts that have no comments to track unanswered questions
UNION ALL
SELECT 
    p.Title,
    u.Reputation,
    p.ViewCount,
    0 AS CommentCount,
    0 AS UpVotes,
    0 AS DownVotes,
    0 AS NetVotes
FROM 
    Posts p
INNER JOIN 
    Users u ON u.Id = p.OwnerUserId
WHERE 
    p.CommentCount = 0
    AND p.CreationDate >= NOW() - INTERVAL '1 year'
ORDER BY 
    u.Reputation DESC 
LIMIT 5;
