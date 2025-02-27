
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        COALESCE(NULLIF(TRIM(p.Tags), ''), 'No Tags') AS CleanTags,
        COUNT(t.TagName) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.TagName IN (SELECT TRIM(value) FROM JSON_TABLE(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '$[*]' COLUMNS(value VARCHAR(255) PATH '$')) AS j)
    GROUP BY 
        p.Id, p.Title, p.Tags
),
UserReputationStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        (@rank := @rank + 1) AS Rank
    FROM 
        Posts p, (SELECT @rank := 0) r
    WHERE 
        p.ViewCount IS NOT NULL
    ORDER BY 
        p.ViewCount DESC
)
SELECT 
    p.PostId,
    p.Title AS PostTitle,
    p.TagCount,
    u.DisplayName AS PostOwner,
    u.TotalBadgeClass,
    u.TotalPosts,
    u.TotalScore,
    pp.Rank,
    pp.CreationDate AS PopularityDate
FROM 
    PostTagCounts p
JOIN 
    UserReputationStats u ON p.PostId = u.UserId
JOIN 
    PopularPosts pp ON p.PostId = pp.PostId
WHERE 
    p.TagCount > 3
ORDER BY 
    pp.Rank, u.TotalScore DESC;
