WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY STRING_AGG(t.TagName, ',') ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int)
    WHERE 
        p.PostTypeId = 1 -- Only consider questions
    GROUP BY 
        p.Id, u.DisplayName
),
DistinctTags AS (
    SELECT DISTINCT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
PostInfo AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Body,
        rp.Tags,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        tt.TagName
    FROM 
        RankedPosts rp
    JOIN 
        DistinctTags tt ON tt.TagName = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
    WHERE 
        rp.Rank <= 5 -- Top 5 posts for each tag
)
SELECT 
    pi.Title,
    pi.CreationDate,
    pi.ViewCount,
    pi.Score,
    pi.OwnerDisplayName,
    STRING_AGG(pi.TagName, ', ') AS RelatedTags
FROM 
    PostInfo pi
JOIN 
    Posts p ON pi.PostId = p.Id
GROUP BY 
    pi.PostId, pi.Title, pi.CreationDate, pi.ViewCount, pi.Score, pi.OwnerDisplayName
ORDER BY 
    pi.ViewCount DESC
LIMIT 50;
