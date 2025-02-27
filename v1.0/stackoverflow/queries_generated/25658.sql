WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- posts created in the last year
),
TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),
PopularTags AS (
    SELECT 
        Tag,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS PopularityRank
    FROM 
        TagCounts
    WHERE 
        TagCount > 10 -- only tags with more than 10 occurrences
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS ActionTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.Reputation,
    pt.Tag AS PopularTag,
    pha.HistoryCount,
    pha.ActionTypes
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON pt.Tag = ANY (string_to_array(substring(rp.Tags, 2, length(rp.Tags) - 2), '><'))
LEFT JOIN 
    PostHistoryAnalysis pha ON pha.PostId = rp.PostId
WHERE 
    rp.PostRank = 1 -- only the most viewed post of each user
ORDER BY 
    rp.ViewCount DESC, 
    rp.Reputation DESC
LIMIT 50;
