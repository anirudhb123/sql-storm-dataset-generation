-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    GROUP BY 
        u.Id, u.Reputation
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(COUNT(ph.Id), 0) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
)
SELECT 
    us.UserId,
    us.Reputation,
    us.PostCount,
    us.BadgeCount,
    us.UpVotes,
    us.DownVotes,
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.ViewCount,
    pa.Score,
    pa.CommentCount,
    pa.EditCount
FROM 
    UserStats us
JOIN 
    PostActivity pa ON us.UserId = pa.OwnerUserId
ORDER BY 
    us.Reputation DESC, 
    pa.ViewCount DESC;
