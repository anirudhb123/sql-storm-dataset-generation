WITH PostWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        COALESCE(ARRAY_AGG(DISTINCT t.TagName) FILTER (WHERE t.TagName IS NOT NULL), ARRAY[]::varchar[]) AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            pt.PostId, 
            unnest(string_to_array(substring(pt.Tags, 2, length(pt.Tags) - 2), '><')) AS TagName 
         FROM 
            Posts pt 
         WHERE 
            pt.PostTypeId = 1) t ON t.PostId = p.Id 
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id
), AdjustedPostScores AS (
    SELECT 
        pwt.PostId,
        pwt.Title,
        pwt.Body,
        pwt.CreationDate,
        pwt.Score * (1 + COUNT(c.Id)) AS AdjustedScore, -- Increase score based on the number of comments
        pwt.TagList
    FROM 
        PostWithTags pwt
    LEFT JOIN 
        Comments c ON c.PostId = pwt.PostId 
    GROUP BY 
        pwt.PostId, pwt.Title, pwt.Body, pwt.CreationDate, pwt.Score, pwt.TagList
), TopPosts AS (
    SELECT 
        aps.PostId,
        aps.Title,
        aps.Body,
        aps.AdjustedScore,
        aps.CreationDate,
        row_number() OVER (ORDER BY aps.AdjustedScore DESC) AS Rank
    FROM 
        AdjustedPostScores aps
    WHERE 
        aps.AdjustedScore > 0 -- Exclude posts with non-positive scores
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.AdjustedScore,
    tp.CreationDate,
    tp.Rank,
    array_to_string(tp.TagList, ', ') AS Tags
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10 -- Get top 10 posts
ORDER BY 
    tp.AdjustedScore DESC;
