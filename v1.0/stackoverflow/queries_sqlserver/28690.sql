
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > DATEADD(year, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.Tags, u.DisplayName
),
TagStatistics AS (
    SELECT 
        REPLACE(tag.tagname, '<', '') AS CleanedTag,
        COUNT(*) AS PostCount,
        AVG(p.ViewCount) AS AvgViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    CROSS APPLY (
        SELECT 
            value AS tagname 
        FROM 
            STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>') 
    ) AS tag
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        CleanedTag
),
TopTags AS (
    SELECT 
        CleanedTag,
        PostCount,
        AvgViews,
        AvgScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
    WHERE 
        PostCount > 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerName,
    rp.CommentCount,
    tt.CleanedTag,
    tt.AvgViews,
    tt.AvgScore
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON tt.CleanedTag IN (
        SELECT 
            TRIM(value) 
        FROM 
            STRING_SPLIT(SUBSTRING(rp.Tags, 2, LEN(rp.Tags) - 2), '>') 
    )
WHERE 
    rp.Rank <= 3 
ORDER BY 
    tt.PostCount DESC, rp.ViewCount DESC;
