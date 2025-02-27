
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
        p.PostTypeId = 1 
    AND 
        p.CreationDate > DATEADD(year, -1, '2024-10-01 12:34:56')
),
FilteredTags AS (
    SELECT 
        DISTINCT value AS Tag
    FROM 
        STRING_SPLIT(Tags, '><')
    WHERE 
        Tags IS NOT NULL
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
    RankedPosts fp ON fp.Tags LIKE '%' + ft.Tag + '%'
GROUP BY 
    ft.Tag
HAVING 
    COUNT(fp.PostId) > 5 
ORDER BY 
    AvgViewCount DESC, AvgOwnerReputation DESC;
