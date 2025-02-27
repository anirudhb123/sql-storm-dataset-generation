-- Performance Benchmarking Query
-- This query retrieves the top 10 most viewed posts within the last year along with their associated user and vote details.

WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.Id AS UserId,
        u.DisplayName AS UserDisplayName,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.UserId,
    rp.UserDisplayName,
    rp.UpVotes,
    rp.DownVotes
FROM 
    RecentPosts rp
ORDER BY 
    rp.ViewCount DESC
LIMIT 10;
