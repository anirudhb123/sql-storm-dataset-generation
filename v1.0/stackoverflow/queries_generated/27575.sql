WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 AND  -- Only Questions
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Last one year
)

SELECT 
    rp.OwnerDisplayName,
    SUM(rp.ViewCount) AS TotalViews,
    COUNT(rp.PostId) AS QuestionCount,
    AVG(rp.Score) AS AverageScore,
    STRING_AGG(DISTINCT tag.TagName, ', ') AS TagsUsed,
    STRING_AGG(DISTINCT ph.Comment, '; ') AS EditComments
FROM 
    RankedPosts rp
LEFT JOIN 
    Posts p ON rp.PostId = p.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6)  -- Only Edit Title, Body or Tags
LEFT JOIN 
    STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag ON TRUE
WHERE 
    rp.Rank = 1  -- Top question per user
GROUP BY 
    rp.OwnerDisplayName
ORDER BY 
    TotalViews DESC
LIMIT 10;
