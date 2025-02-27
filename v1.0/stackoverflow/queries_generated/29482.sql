WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) as rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
PopularTags AS (
    SELECT
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName,
        COUNT(*) AS UsageCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        TagName
),
TrendingPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Owner,
        rp.CommentCount,
        pt.TagName,
        pt.UsageCount,
        ROW_NUMBER() OVER (PARTITION BY rp.PostId ORDER BY pt.UsageCount DESC) as TagRank
    FROM 
        RankedPosts rp
    JOIN 
        PopularTags pt ON p.Tags LIKE '%<' || pt.TagName || '>%'
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.Owner,
    tp.CommentCount,
    pt.TagName AS PopularTag,
    pt.UsageCount
FROM 
    TrendingPosts tp
JOIN 
    PopularTags pt ON tp.TagName = pt.TagName
WHERE 
    tp.TagRank = 1 -- Only take the most popular tag for each post
ORDER BY 
    tp.ViewCount DESC, tp.Score DESC
LIMIT 10;
This SQL query performs string processing by extracting tags from posts and correlating them with the post details. It retrieves the top 10 questions based on their view count and score while highlighting the most used tag associated with each question. The use of common table expressions (CTEs) helps to structure the query clearly and efficiently.
