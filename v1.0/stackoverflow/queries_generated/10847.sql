-- Performance Benchmarking Query

-- This query retrieves the most recent posts along with their user information, tag counts, and vote statistics
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        u.Id AS UserId,
        u.DisplayName AS UserDisplayName,
        COUNT(DISTINCT t.Id) AS TagCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END) AS CloseVotes,
        SUM(CASE WHEN v.VoteTypeId = 11 THEN 1 ELSE 0 END) AS OpenVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'  -- Filter for recent posts
    GROUP BY 
        p.Id, u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.PostCreationDate,
    rp.UserId,
    rp.UserDisplayName,
    rp.TagCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.CloseVotes,
    rp.OpenVotes
FROM 
    RecentPosts rp
ORDER BY 
    rp.PostCreationDate DESC
LIMIT 100;  -- Limit the result set to the most recent 100 posts
