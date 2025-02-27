WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UpvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- 2 = UpMod (Upvote)
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.UpvoteCount,
    pt.Name AS PostTypeName,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     WHERE t.Id IN (SELECT UNNEST(string_to_array(p.Tags, '>'))::int)) AS TagsList
FROM 
    RankedPosts rp
JOIN 
    PostTypes pt ON rp.Rank = pt.Id
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
