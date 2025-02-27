WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Filter for questions only
    GROUP BY 
        p.Id, u.DisplayName
),

RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        (SELECT STRING_AGG(DISTINCT CONCAT(u.DisplayName, ' (', h.CreationDate, ')'), '; ') 
         FROM PostHistory h 
         JOIN Users u ON h.UserId = u.Id 
         WHERE h.PostId = p.Id 
         AND h.CreationDate >= NOW() - INTERVAL '30 days') AS RecentEdits,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = p.Id 
         AND c.CreationDate >= NOW() - INTERVAL '30 days') AS RecentCommentCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.VoteCount,
    ra.RecentEdits,
    ra.RecentCommentCount
FROM 
    RankedPosts rp
JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
WHERE 
    rp.PostRank <= 5  -- Limit to top 5 recent posts per user
ORDER BY 
    rp.CreationDate DESC;
