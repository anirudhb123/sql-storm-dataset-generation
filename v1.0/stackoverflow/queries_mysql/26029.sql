
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName ASC SEPARATOR ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.Tags, '><', n.n), '><', -1)) AS tag
        FROM (SELECT @row := @row + 1 AS n FROM
              (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
               SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) t,
              (SELECT @row := 0) r
             ) n
        WHERE n.n <= LENGTH(t.Tags) - LENGTH(REPLACE(t.Tags, '><', '')) + 1
    ) AS tag_names ON FIND_IN_SET(tag_names.tag, REPLACE(REPLACE(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><', ','), ' ', '')) > 0
    LEFT JOIN Tags t ON t.TagName = tag_names.tag
    WHERE p.PostTypeId = 1 AND p.Score > 0
    GROUP BY p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Author,
    rp.CommentCount,
    rp.Tags,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top Contributor'
        WHEN rp.Rank BETWEEN 6 AND 10 THEN 'Moderate Contributor'
        ELSE 'Needs Improvement'
    END AS ContributorLevel
FROM RankedPosts rp
WHERE rp.CommentCount > 0
ORDER BY rp.Score DESC, rp.ViewCount DESC
LIMIT 100;
