WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COALESCE((SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        (SELECT COUNT(v.Id) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(v.Id) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        LOWER(TRIM(SUBSTRING(tag.TagName FROM 2 FOR CHAR_LENGTH(tag.TagName) - 2))) AS TagName,
        SUM(tag.Count) AS TotalCount
    FROM 
        Tags tag
    GROUP BY 
        tag.TagName
    HAVING 
        SUM(tag.Count) > 100
),
PostComments AS (
    SELECT 
        pc.PostId,
        STRING_AGG(c.Text, ' | ') AS AllComments
    FROM 
        Comments c
    INNER JOIN 
        Posts pc ON pc.Id = c.PostId
    GROUP BY 
        pc.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.RankScore,
    pt.TagName,
    pc.AllComments,
    rp.CommentCount,
    (rp.UpVotes - rp.DownVotes) AS NetVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    PostLinks pl ON pl.PostId = rp.PostId
LEFT JOIN 
    Tags pt ON pt.ExcerptPostId = pl.RelatedPostId
LEFT JOIN 
    PostComments pc ON pc.PostId = rp.PostId
WHERE 
    rp.RankScore <= 5
    AND pt.TagName IN (SELECT TagName FROM PopularTags)
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;

