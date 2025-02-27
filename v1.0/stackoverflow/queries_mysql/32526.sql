
WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COUNT(p.Id) AS PostsCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9)  
    WHERE u.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.LastAccessDate
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        @loc_rank := IF(@prev_loc = u.Location, @loc_rank + 1, 1) AS LocationRank,
        @prev_loc := u.Location
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @loc_rank := 0, @prev_loc := '') AS vars
    WHERE p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
      AND p.PostTypeId = 1  
    ORDER BY u.Location, p.CreationDate DESC
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS TagsList
    FROM Posts p
    JOIN (
        SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1)) AS tag
        FROM Posts p
        INNER JOIN (
            SELECT DISTINCT @rownum := @rownum + 1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t
            CROSS JOIN (SELECT @rownum := 0) r
        ) n
        WHERE n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) + 1
    ) AS tag ON tag IS NOT NULL
    JOIN Tags t ON t.TagName = tag.tag
    GROUP BY p.Id
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    p.PostId,
    p.Title AS Recent_Post_Title,
    p.CreationDate AS Recent_Post_CreationDate,
    COALESCE(pt.TagsList, 'No Tags') AS PostTags,
    p.ViewCount,
    p.Score,
    p.OwnerDisplayName,
    ua.TotalBountyAmount
FROM UserActivity ua
LEFT JOIN RecentPosts p ON ua.UserId = (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = p.PostId)
LEFT JOIN PostTags pt ON p.PostId = pt.PostId
WHERE ua.Reputation > 1000 
  AND p.LocationRank <= 3  
ORDER BY ua.Reputation DESC, p.CreationDate DESC;
