WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Author,
    rp.RankScore,
    COALESCE(rp.CommentCount, 0) AS TotalComments,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes, -- counting upvotes
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotes, -- counting downvotes
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Tags t 
     WHERE t.Id IN (SELECT UNNEST(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))::int)) 
    ) AS TagList
FROM 
    RankedPosts rp
WHERE 
    rp.RankScore <= 10 -- Include only top 10 ranked posts per type
ORDER BY 
    rp.PostTypeId, rp.RankScore;
