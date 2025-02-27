WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY tag ORDER BY p.Score DESC) AS Rank,
        STRING_AGG(tag, ', ') AS AllTags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, u.Reputation
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        Reputation,
        AllTags,
        Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 -- Top 5 posts by score per tag
),
TagData AS (
    SELECT 
        tag,
        COUNT(*) AS PostCount,
        AVG(Reputation) AS AvgReputation
    FROM 
        FilteredPosts
    CROSS JOIN 
        UNNEST(string_to_array(AllTags, ', ')) AS tag
    GROUP BY 
        tag
)
SELECT 
    td.tag,
    td.PostCount,
    td.AvgReputation,
    ARRAY_AGG(fp.OwnerDisplayName) AS TopContributors,
    ARRAY_AGG(fp.Title ORDER BY fp.Score DESC) AS TopPosts
FROM 
    TagData td
JOIN 
    FilteredPosts fp ON fp.AllTags LIKE '%' || td.tag || '%'
GROUP BY 
    td.tag, td.PostCount, td.AvgReputation
ORDER BY 
    td.PostCount DESC, td.AvgReputation DESC;
