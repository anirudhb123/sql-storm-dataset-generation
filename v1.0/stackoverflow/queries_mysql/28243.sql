
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        GROUP_CONCAT(DISTINCT u.DisplayName SEPARATOR ', ') AS Contributors
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= '2024-10-01' - INTERVAL 1 YEAR
    GROUP BY p.Id, pt.Name, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.Tags
),
TopContributors AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(*) AS TotalContributions
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE p.CreationDate >= '2024-10-01' - INTERVAL 1 YEAR
    GROUP BY u.Id, u.DisplayName
    HAVING COUNT(*) > 5
),
PostTags AS (
    SELECT
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1) AS Tag
    FROM Posts p
    JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
          UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
          UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Tags,
    rp.Contributors,
    tt.TotalContributions,
    COUNT(pt.Tag) AS TagCount
FROM RankedPosts rp
LEFT JOIN TopContributors tt ON FIND_IN_SET(tt.DisplayName, rp.Contributors)
LEFT JOIN PostTags pt ON rp.PostId = pt.PostId
WHERE rp.Rank <= 5
GROUP BY rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.ViewCount, rp.Score, rp.Tags, rp.Contributors, tt.TotalContributions
ORDER BY rp.Score DESC;
