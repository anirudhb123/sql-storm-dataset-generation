
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS UpVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    LEFT JOIN 
        (SELECT value AS TagName FROM STRING_SPLIT(p.Tags, '><')) AS t ON 1=1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
)

SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    rp.Score, 
    rp.CommentCount, 
    rp.UpVoteCount, 
    rp.Rank,
    rp.Tags
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
