WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 -- Filtering for questions
),
TagSummary AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - CreationDate))) AS AvgAgeInSeconds
    FROM Posts
    WHERE PostTypeId = 1 -- Questions only
    GROUP BY Tag
),
PopularTags AS (
    SELECT 
        Tag,
        PostCount,
        AvgAgeInSeconds
    FROM TagSummary
    WHERE PostCount > 10
)
SELECT 
    rp.Title,
    rp.Body,
    rp.Author,
    rp.CreationDate,
    pt.Tag,
    pt.PostCount,
    pt.AvgAgeInSeconds
FROM RankedPosts rp
JOIN PopularTags pt ON rp.Tags LIKE '%' || pt.Tag || '%'
WHERE rp.Rank <= 5 -- Top 5 questions per tag
ORDER BY pt.PostCount DESC, rp.Score DESC;
