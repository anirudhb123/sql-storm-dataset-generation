WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        p.CreationDate, 
        p.LastActivityDate, 
        u.DisplayName AS OwnerDisplayName, 
        pf.BadgesCount, 
        ROW_NUMBER() OVER (PARTITION BY COALESCE(p.Tags, 'NoTag') ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            UserId, COUNT(*) AS BadgesCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) pf ON u.Id = pf.UserId
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
), TagStatistics AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '> <')) AS Tag,
        AVG(p.Score) AS AvgScore,
        COUNT(*) AS PostCount
    FROM 
        Posts p
    WHERE
        p.PostTypeId = 1
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        Tag
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.OwnerDisplayName,
    ts.Tag,
    ts.AvgScore,
    ts.PostCount
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON ts.Tag = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags) - 2), '> <'))
WHERE 
    rp.Rank <= 5
ORDER BY 
    ts.AvgScore DESC,
    rp.Score DESC;
