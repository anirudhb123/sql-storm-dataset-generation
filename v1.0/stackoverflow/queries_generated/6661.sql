WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS RankOrder
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) -- Questions and Answers
    GROUP BY 
        p.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(p.Tags, '>')) AS TagName,
        COUNT(*) AS Count
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        TagName
    ORDER BY 
        Count DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    pt.TagName,
    pt.Count AS TagPostCount
FROM 
    RankedPosts rp
JOIN 
    PostLinks pl ON rp.PostId = pl.PostId
JOIN 
    PopularTags pt ON pl.RelatedPostId IN (SELECT PostId FROM Posts WHERE Tags LIKE CONCAT('%', pt.TagName, '%'))
WHERE 
    rp.RankOrder <= 50 -- Top 50 recent posts
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
