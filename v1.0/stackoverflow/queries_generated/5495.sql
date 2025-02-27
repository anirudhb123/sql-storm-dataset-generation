WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '') AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.Tags
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        AVG(u.Reputation) AS AvgReputation,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Tags,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    ur.DisplayName,
    ur.AvgReputation,
    ur.PostsCount
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
WHERE 
    rp.UserPostRank = 1
ORDER BY 
    rp.Score DESC,
    rp.ViewCount DESC;
