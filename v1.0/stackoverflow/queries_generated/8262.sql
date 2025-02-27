WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        pt.Name = 'Question'
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Owner,
    rp.CommentCount,
    pt.TagName
FROM 
    RankedPosts rp
JOIN 
    PostLinks pl ON rp.PostId = pl.PostId
JOIN 
    PopularTags pt ON pl.RelatedPostId IN (SELECT PostId FROM Posts p WHERE p.Tags LIKE CONCAT('%', pt.TagName, '%'))
WHERE 
    rp.PostRank <= 10
ORDER BY 
    rp.PostRank;
