-- Performance Benchmarking Query

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,   -- UpMod
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes, -- DownMod
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.UpVotes,
    rp.DownVotes,
    rp.CommentCount,
    rp.BadgeCount
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 100 -- Fetch top 100 recent posts
ORDER BY 
    rp.CreationDate DESC;
