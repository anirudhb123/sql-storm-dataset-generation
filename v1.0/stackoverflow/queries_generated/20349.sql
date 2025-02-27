WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND
        p.Score IS NOT NULL
),
HighScoringUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostLinksWithTags AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        STRING_AGG(t.TagName, ', ') AS RelatedTags
    FROM 
        PostLinks pl
    LEFT JOIN 
        Posts p ON pl.RelatedPostId = p.Id
    LEFT JOIN 
        LATERAL STRING_TO_ARRAY(substring(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        pl.PostId, pl.RelatedPostId
) 
SELECT 
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    u.DisplayName AS TopUser,
    h.TotalScore,
    h.AvgScore,
    COALESCE(pw.RelatedTags, 'No Related Tags') AS RelatedTags
FROM 
    RankedPosts r
JOIN 
    HighScoringUsers h ON r.PostRank = 1
JOIN 
    Users u ON h.UserId = u.Id
LEFT JOIN 
    PostLinksWithTags pw ON r.PostId = pw.PostId
WHERE 
    r.AcceptedAnswerId IN (SELECT Id FROM Posts WHERE Score IS NOT NULL AND Score > 0)
ORDER BY 
    r.Score DESC, u.Reputation DESC
LIMIT 10;


