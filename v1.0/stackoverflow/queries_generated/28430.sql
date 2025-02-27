WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate > NOW() - INTERVAL '1 year' -- Last year
),
TagFrequency AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS Frequency
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),
MostFrequentTags AS (
    SELECT 
        Tag,
        Frequency,
        ROW_NUMBER() OVER (ORDER BY Frequency DESC) AS TagRank
    FROM 
        TagFrequency
    WHERE 
        Frequency > 5 -- Tags used more than 5 times
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        mf.Tag
    FROM 
        RankedPosts rp
    JOIN 
        MostFrequentTags mf ON rp.Tags LIKE '%' || mf.Tag || '%'
    WHERE 
        rp.Rank = 1 -- Only most recent post per tag
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.Score,
    tp.Tag
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewCount DESC
LIMIT 10; -- Get top 10 posts based on view count and recent activity
This SQL query benchmarks string processing against various conditions by performing the following steps:
1. **RankedPosts CTE**: Select the most recent questions from the last year and rank them by their tags.
2. **TagFrequency CTE**: Count how frequently each tag is used across all questions.
3. **MostFrequentTags CTE**: Identify tags that have been used more than five times and assign a rank to them.
4. **TopPosts CTE**: Join the ranked posts with the most frequent tags to get the top recent posts along with their view count and score.
5. **Final Selection**: Retrieve the top 10 posts ordered by view count.
