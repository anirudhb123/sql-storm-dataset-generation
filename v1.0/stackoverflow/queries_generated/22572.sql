WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate,
        p.ViewCount, 
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,  -- Count of UpVotes
        SUM(v.VoteTypeId = 3) AS DownVotes, -- Count of DownVotes
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId
), 
FilteredPosts AS (
    SELECT 
        rp.*, 
        CASE 
            WHEN rp.UpVotes >= 5 THEN 'Popular'
            ELSE 'Regular'
        END AS Popularity,
        CASE 
            WHEN rp.CommentCount = 0 THEN NULL 
            ELSE ROUND((rp.UpVotes::float / NULLIF(rp.CommentCount, 0)) * 100, 2) 
        END AS EngagementScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 -- Select only latest post per user
)
SELECT 
    f.Id,
    f.Title,
    f.CreationDate,
    f.ViewCount,
    f.CommentCount,
    f.UpVotes,
    f.DownVotes,
    f.Popularity,
    f.EngagementScore,
    pt.Name AS PostTypeName,
    CONCAT('https://example.com/posts/', f.Id) AS PostUrl
FROM 
    FilteredPosts f
JOIN 
    PostTypes pt ON pt.Id = (SELECT p.PostTypeId FROM Posts p WHERE p.Id = f.Id)
WHERE 
    f.EngagementScore IS NOT NULL
ORDER BY 
    f.EngagementScore DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM FilteredPosts) / 2; -- Get the middle half for benchmarking
