WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        ARRAY_AGG(t.TagName) AS TagsArray,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS t(TagName)
    WHERE 
        p.PostTypeId = 1 -- Questions
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        rp.TagsArray
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 5 -- Top 5 questions per user
),
PopularTags AS (
    SELECT 
        unnest(rp.TagsArray) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        TopPosts rp
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10 -- Top 10 most used tags in the top questions
)
SELECT 
    pt.TagName,
    pt.TagCount,
    (SELECT COUNT(DISTINCT PostId) FROM TopPosts WHERE TagsArray @> ARRAY[pt.TagName]) AS AssociatedPostCount
FROM 
    PopularTags pt;
This query first identifies the top 5 questions by score for each user, aggregates the associated tags, and then determines the 10 most popular tags among those questions along with their associated post counts, showcasing string processing in tag handling.
