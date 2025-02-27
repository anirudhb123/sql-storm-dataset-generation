
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedLinksCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId 
    WHERE p.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        RANK() OVER (ORDER BY SUM(u.UpVotes) - SUM(u.DownVotes) DESC) AS UserRank
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
    ORDER BY UserRank
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UpVotesCount,
    rp.DownVotesCount,
    rp.CommentsCount,
    rp.RelatedLinksCount,
    tu.DisplayName AS TopUser,
    CASE
        WHEN rp.Score > 10 THEN 'Popular'
        WHEN rp.Score BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Less Popular'
    END AS PopularityIndicator,
    COALESCE((
        SELECT GROUP_CONCAT(gh.Tag SEPARATOR ', ')
        FROM (
            SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1)) AS Tag
            FROM Posts p
            JOIN (
                SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
                SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
                SELECT 9 UNION ALL SELECT 10
            ) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
            WHERE p.Id = rp.PostId
        ) gh
    ), 'No Tags') AS Tags
FROM RecentPosts rp
LEFT JOIN TopUsers tu ON rp.UpVotesCount > 5 AND rp.DownVotesCount < 3
ORDER BY rp.CreationDate DESC
LIMIT 20;
