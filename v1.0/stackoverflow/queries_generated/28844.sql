WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagList,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    WHERE 
        p.CreatedDate >= CURRENT_DATE - INTERVAL '30 days'
      AND 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.ViewCount
    HAVING 
        COUNT(c.Id) > 5 -- More than 5 comments
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CommentCount,
        rp.TagList,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName
    FROM 
        RankedPosts rp
    INNER JOIN 
        Posts p ON rp.PostId = p.Id
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
)
SELECT 
    COUNT(*) AS TotalFilteredPosts,
    AVG(ViewCount) AS AvgViews,
    AVG(CommentCount) AS AvgComments,
    STRING_AGG(DISTINCT unnest(TagList), ', ') AS AllTags
FROM 
    FilteredPosts;
