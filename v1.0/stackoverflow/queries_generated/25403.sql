WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS Author,
        u.Reputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND  -- Filtering to consider only questions
        p.CreationDate >= NOW() - INTERVAL '6 months'  -- Considering recent posts
),

TagCounts AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS TagFrequency
    FROM 
        RankedPosts
    GROUP BY 
        TagName
),

FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.Reputation,
        rp.ViewCount,
        rp.Score,
        tc.TagName,
        tc.TagFrequency
    FROM 
        RankedPosts rp
    JOIN 
        TagCounts tc ON rp.Tags LIKE '%' || tc.TagName || '%'  -- Making sure to match the tags
    WHERE 
        rp.Rank <= 5  -- Only select the top 5 questions per user
)

SELECT 
    fr.PostId,
    fr.Title,
    fr.Author,
    fr.Reputation,
    fr.ViewCount,
    fr.Score,
    fr.TagName,
    fr.TagFrequency
FROM 
    FinalResults fr
ORDER BY 
    fr.Reputation DESC, 
    fr.Score DESC;  -- Order by user reputation and post score to showcase the best contributions
