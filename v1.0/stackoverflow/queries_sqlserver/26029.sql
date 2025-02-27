
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
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    OUTER APPLY (SELECT TRIM(value) AS tag FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')) AS tag_names 
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
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
