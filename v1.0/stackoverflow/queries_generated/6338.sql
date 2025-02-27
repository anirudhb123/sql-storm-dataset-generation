WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(p.Tags, '>')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.CommentCount,
    pt.TagName,
    pt.TagCount
FROM 
    RankedPosts rp
JOIN 
    PostTags pt ON rp.PostId = pt.PostId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate ASC;
