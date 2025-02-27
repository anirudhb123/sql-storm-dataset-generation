WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.LastActivityDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2 
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Questions from the last year
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate, p.LastActivityDate, p.Score
),
TopTags AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS TagName
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 -- Top 5 highest-ranking posts per tag
),
TagStats AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount,
        AVG(p.Score) AS AvgScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        TopTags tt
    JOIN 
        Posts p ON p.Tags LIKE '%' || tt.TagName || '%'
    GROUP BY 
        TagName
    ORDER BY 
        PostCount DESC
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.AvgScore,
    ts.AvgViewCount,
    RANK() OVER (ORDER BY ts.PostCount DESC) AS PopularityRank
FROM 
    TagStats ts
WHERE 
    ts.PostCount > 5; -- Only consider tags with more than 5 posts
