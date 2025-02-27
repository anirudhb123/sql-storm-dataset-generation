WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(c.Id) DESC, p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
RecentActivity AS (
    SELECT 
        PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory
    WHERE 
        CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    ra.EditCount,
    rp.PostRank
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
WHERE 
    rp.PostRank <= 10 -- Top 10 posts
ORDER BY 
    rp.PostRank;
