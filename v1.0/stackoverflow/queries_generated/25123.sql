WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC, SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS RankByUser
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, ',')) AS tagName ON TRUE
    LEFT JOIN 
        Tags t ON TRIM(BOTH ' ' FROM tagName) = t.TagName
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'  -- Only consider recent posts
    GROUP BY 
        p.Id
)

SELECT 
    u.DisplayName AS Author,
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.Tags
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
WHERE 
    rp.RankByUser <= 5  -- Get top 5 posts for each user

ORDER BY 
    u.DisplayName, 
    rp.CreationDate DESC;
