
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        DATEDIFF(SECOND, p.CreationDate, '2024-10-01 12:34:56') AS AgeInSeconds
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    AND 
        (p.Body LIKE '%performance%' OR p.Title LIKE '%performance%')
),
PostTagCounts AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    CROSS APPLY STRING_SPLIT(Tags, ',') 
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        value
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        PostTagCounts
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    rp.AgeInSeconds,
    tt.Tag AS TopTag
FROM 
    RankedPosts rp
LEFT JOIN 
    TopTags tt ON tt.TagRank <= 5
WHERE 
    rp.Rank <= 10
GROUP BY 
    rp.PostId, rp.Title, rp.OwnerDisplayName, rp.Score, rp.ViewCount, rp.AgeInSeconds, tt.Tag
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
