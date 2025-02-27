WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        row_number() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- considering only questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- within last year
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerName,
        rp.Score,
        rp.ViewCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 -- top 5 questions by score per tag
),
TagSummary AS (
    SELECT 
        UNNEST(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore
    FROM 
        TopPosts
    GROUP BY 
        TagName
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalScore,
    (SELECT COUNT(DISTINCT t.TagName) FROM TagSummary t) AS UniqueTagsCount,
    (SUM(ts.TotalScore) FILTER (WHERE ts.PostCount > 1)) AS AggregateScoreForMultiplePosts
FROM 
    TagSummary ts
GROUP BY 
    ts.TagName
ORDER BY 
    ts.TotalScore DESC;
