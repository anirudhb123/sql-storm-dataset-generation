WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RowNum,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounties,
        STRING_AGG(t.TagName, ', ') FILTER (WHERE t.TagName IS NOT NULL) OVER (PARTITION BY p.Id) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart votes
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS t(TagName) ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    u.DisplayName,
    COUNT(DISTINCT rp.PostId) AS PostCount,
    SUM(rp.Score) AS TotalScore,
    AVG(rp.Score) AS AverageScore,
    MAX(rp.CommentCount) AS MaxComments,
    SUM(rp.TotalBounties) AS TotalBountiesEarned,
    LISTAGG(DISTINCT rp.Tags, ', ') AS CombinedTags
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.RowNum = 1 AND u.Id = rp.OwnerUserId
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT rp.PostId) > 5 
ORDER BY 
    TotalScore DESC;
