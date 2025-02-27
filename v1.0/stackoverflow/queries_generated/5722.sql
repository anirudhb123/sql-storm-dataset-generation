WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
), 

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
    HAVING 
        SUM(v.VoteTypeId = 2) > SUM(v.VoteTypeId = 3)
)

SELECT 
    r.PostId,
    r.Title,
    r.Score,
    r.CreationDate,
    r.OwnerDisplayName,
    r.CommentCount,
    t.UserId,
    t.DisplayName AS TopUser,
    t.UpVotes,
    t.DownVotes,
    t.BadgeCount
FROM 
    RankedPosts r
JOIN 
    TopUsers t ON r.OwnerDisplayName = t.DisplayName
WHERE 
    r.RankByScore <= 10
ORDER BY 
    r.Score DESC, t.UpVotes DESC;
