
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
        LISTAGG(DISTINCT u.DisplayName, ', ') WITHIN GROUP (ORDER BY u.DisplayName) AS Contributors
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= DATEADD(year, -1, '2024-10-01')
    GROUP BY p.Id, pt.Name, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.Tags
),
TopContributors AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(*) AS TotalContributions
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE p.CreationDate >= DATEADD(year, -1, '2024-10-01')
    GROUP BY u.Id, u.DisplayName
    HAVING COUNT(*) > 5
),
PostTags AS (
    SELECT
        p.Id AS PostId,
        tag AS Tag
    FROM Posts p,
    LATERAL SPLIT_TO_TABLE(p.Tags, ',') AS tag
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
LEFT JOIN TopContributors tt ON POSITION(tt.DisplayName IN rp.Contributors) > 0
LEFT JOIN PostTags pt ON rp.PostId = pt.PostId
WHERE rp.Rank <= 5
GROUP BY rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.ViewCount, rp.Score, rp.Tags, rp.Contributors, tt.TotalContributions
ORDER BY rp.Score DESC;
