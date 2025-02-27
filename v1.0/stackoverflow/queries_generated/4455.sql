WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.Tags, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.Tags,
        ur.UserRank,
        rp.CommentCount,
        (rp.UpVotes - rp.DownVotes) AS NetVotes
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.PostRank = 1 AND ur.UserRank <= 10
)
SELECT 
    tp.Title,
    tp.Score,
    tp.CreationDate,
    tp.Tags,
    tp.CommentCount,
    tp.NetVotes,
    json_agg(DISTINCT bt.Name) AS BadgeNames
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON b.UserId = tp.OwnerUserId
LEFT JOIN 
    PostHistory ph ON ph.PostId = tp.PostId AND ph.PostHistoryTypeId IN (10, 11) -- closing and reopening
LEFT JOIN 
    Badges bt ON bt.UserId = tp.OwnerUserId
WHERE 
    tp.Score IS NOT NULL AND tp.Score > 0
GROUP BY 
    tp.Title, tp.Score, tp.CreationDate, tp.Tags, tp.CommentCount, tp.NetVotes
ORDER BY 
    tp.NetVotes DESC NULLS LAST
LIMIT 50;
