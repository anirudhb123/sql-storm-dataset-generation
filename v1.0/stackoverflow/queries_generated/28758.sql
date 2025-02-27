WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- Focus only on questions
    GROUP BY 
        p.Id, u.DisplayName
),

PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByViews <= 10 -- Top 10 most viewed posts by each user
)

SELECT 
    pp.PostId,
    pp.Title,
    pp.Body,
    pp.CreationDate,
    pp.ViewCount,
    pp.OwnerDisplayName,
    pp.CommentCount,
    ARRAY_AGG(DISTINCT pt.Name) AS PostTags,
    ROW_NUMBER() OVER (ORDER BY pp.ViewCount DESC) AS GlobalRank
FROM 
    PopularPosts pp
LEFT JOIN 
    LATERAL (
        SELECT 
            TRIM(UNNEST(string_to_array(substring(pp.Body, 2, length(pp.Body)-2), '>')))) AS TagName
    ) AS Tags ON TRUE
JOIN 
    Tags t ON t.TagName = Tags.TagName
LEFT JOIN 
    PostTypes pt ON pp.PostId = pt.Id
GROUP BY 
    pp.PostId, pp.Title, pp.Body, pp.CreationDate, pp.ViewCount, pp.OwnerDisplayName, pp.CommentCount
ORDER BY 
    pp.ViewCount DESC, pp.CreationDate DESC;
