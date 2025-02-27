WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.AcceptedAnswerId,
        p.AnswerCount,
        uq.Reputation AS OwnerReputation,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        (SELECT OwnerUserId, SUM(Reputation) AS Reputation FROM Users GROUP BY OwnerUserId) AS uq ON uq.OwnerUserId = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Questions only
    AND 
        p.CreationDate > NOW() - INTERVAL '1 year' -- Posts from the last year
),
FilteredTags AS (
    SELECT 
        DISTINCT unnest(string_to_array(Tags, '><')) AS Tag
    FROM 
        RankedPosts
)
SELECT 
    ft.Tag,
    COUNT(fp.PostId) AS PostCount,
    AVG(fp.ViewCount) AS AvgViewCount,
    AVG(fp.OwnerReputation) AS AvgOwnerReputation,
    COUNT(DISTINCT fp.AcceptedAnswerId) AS AcceptedAnswerCount
FROM 
    FilteredTags ft
LEFT JOIN 
    RankedPosts fp ON fp.Tags LIKE '%' || ft.Tag || '%'
GROUP BY 
    ft.Tag
HAVING 
    COUNT(fp.PostId) > 5 -- Only tags with more than 5 posts
ORDER BY 
    AvgViewCount DESC, AvgOwnerReputation DESC; -- Order by average view count and owner reputation
