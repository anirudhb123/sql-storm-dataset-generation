WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER(ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank 
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id 
    WHERE 
        p.PostTypeId = 1 -- We are filtering only Questions
        AND p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts created in the last year
),
PostTagCounts AS (
    SELECT 
        unnest(string_to_array(p.Tags, '><')) AS Tag, 
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        Tag
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(DISTINCT PostId) AS PostCount,
        SUM(TagCount) AS TotalTagCount
    FROM 
        PostTagCounts
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        TotalTagCount,
        ROW_NUMBER() OVER(ORDER BY PostCount DESC, TotalTagCount DESC) AS Rank 
    FROM 
        TagStatistics
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    tt.Tag,
    tt.PostCount,
    tt.TotalTagCount
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON tt.Rank <= 10 -- Get only top 10 tags
WHERE 
    rp.Rank <= 20 -- Get only top 20 posts
ORDER BY 
    rp.Rank, tt.PostCount DESC;
