WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(c.Id) DESC) AS CommentRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentRank <= 10
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    tp.Title,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    ur.Reputation,
    ur.BadgeCount
FROM 
    TopPosts tp
JOIN 
    Users u ON u.Id = tp.OwnerUserId
JOIN 
    UserReputation ur ON ur.UserId = u.Id
ORDER BY 
    tp.CommentCount DESC, ur.Reputation DESC;
