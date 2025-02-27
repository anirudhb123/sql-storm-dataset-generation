WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes, 
        RANK() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last year
    GROUP BY 
        p.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.Rank,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM 
    RankedPosts rp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
WHERE 
    rp.Rank <= 10 -- Top 10 posts
ORDER BY 
    rp.Rank;
