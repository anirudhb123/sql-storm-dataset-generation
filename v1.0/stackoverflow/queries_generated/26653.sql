WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  -- Considering only Questions for analysis
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Owner,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5  -- Get top 5 recent posts per user
),
TagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(t.Id) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag(t) ON true
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
),
FinalStats AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.Owner,
        fp.ViewCount,
        fp.CommentCount,
        COALESCE(tc.TagCount, 0) AS TagCount
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        TagCounts tc ON fp.PostId = tc.PostId
)
SELECT 
    fs.Owner,
    COUNT(fs.PostId) AS TotalPosts,
    AVG(fs.ViewCount) AS AvgViews,
    SUM(fs.CommentCount) AS TotalComments,
    SUM(fs.TagCount) AS TotalTags
FROM 
    FinalStats fs
GROUP BY 
    fs.Owner
ORDER BY 
    TotalPosts DESC, AvgViews DESC;
