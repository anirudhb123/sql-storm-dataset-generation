WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopTags AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag
    FROM 
        RankedPosts
    WHERE 
        TagRank = 1
),
TagsFrequency AS (
    SELECT 
        Tag,
        COUNT(*) AS Frequency
    FROM 
        TopTags
    GROUP BY 
        Tag
    ORDER BY 
        Frequency DESC
),
MostFrequentTags AS (
    SELECT 
        Tag
    FROM 
        TagsFrequency
    WHERE 
        Frequency > 10 -- threshold for frequent tags
),
CommentStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(c.Score) AS AvgCommentScore
    FROM 
        Posts p
    JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    ts.Frequency AS TagFrequency,
    cs.CommentCount,
    cs.AvgCommentScore
FROM 
    RankedPosts rp
JOIN 
    MostFrequentTags mt ON rp.Tags ILIKE '%' || mt.Tag || '%'
JOIN 
    CommentStats cs ON rp.PostId = cs.PostId
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;

This SQL query benchmarks string processing by extracting the top 100 recent questions (within the past year) based on their score and view count, filtering them by the most frequent tags that have appeared in the posts, while also calculating comment statistics on those posts. It uses Common Table Expressions (CTEs) for organized intermediate steps, leveraging string manipulation for tag extraction and ranking.
