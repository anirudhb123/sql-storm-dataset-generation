WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(co.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments co ON p.Id = co.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
), 
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    INNER JOIN 
        Posts pt ON t.Id = ANY(string_to_array(pt.Tags, '><')::int[])
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.PostId) > 5
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Author,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    pt.TagName
FROM 
    RankedPosts rp
JOIN 
    PostLinks pl ON rp.PostId = pl.PostId
JOIN 
    PopularTags pt ON pl.RelatedPostId = pt.PostCount
WHERE 
    rp.rn = 1
ORDER BY 
    rp.UpVoteCount DESC, rp.CommentCount DESC, rp.CreationDate DESC
LIMIT 10;
