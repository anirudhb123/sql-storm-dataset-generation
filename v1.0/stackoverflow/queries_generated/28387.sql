WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2 
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName
),
AggregatedTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount,
        AVG(p.ViewCount) AS AvgViews,
        MAX(p.AnswerCount) AS MaxAnswers
    FROM 
        AggregatedTags at
    JOIN 
        Posts p ON p.Tags LIKE '%' || at.Tag || '%'
    GROUP BY 
        Tag
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.AnswerCount,
    rp.CommentCount,
    ts.Tag,
    ts.TagCount,
    ts.AvgViews,
    ts.MaxAnswers
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON rp.Tags LIKE '%' || ts.Tag || '%'
WHERE 
    rp.TagRank <= 5 -- Get top 5 ranked posts per tag
ORDER BY 
    ts.TagCount DESC, rp.ViewCount DESC;
