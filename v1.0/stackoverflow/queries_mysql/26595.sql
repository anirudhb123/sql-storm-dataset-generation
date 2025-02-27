
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ah.Id) AS AcceptedAnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Posts ah ON p.AcceptedAnswerId = ah.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Tags IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.Score, p.CreationDate, u.DisplayName
), TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '> <', n.n), '> <', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts p
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
        SELECT 9 UNION ALL SELECT 10
    ) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '> <', '')) >= n.n - 1
    WHERE p.PostTypeId = 1
    GROUP BY TagName
    HAVING COUNT(*) > 10 
), TagRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.Score,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        ts.TagName,
        ts.PostCount,
        ROW_NUMBER() OVER (PARTITION BY ts.TagName ORDER BY rp.Score DESC) AS TagPostRank
    FROM RankedPosts rp
    JOIN TagStatistics ts ON rp.Tags LIKE CONCAT('%', ts.TagName, '%')
)

SELECT 
    t.TagName,
    COUNT(*) AS TotalPostsUnderTag,
    MAX(rp.Score) AS HighestScore,
    AVG(rp.Score) AS AverageScore,
    GROUP_CONCAT(rp.Title ORDER BY rp.Score DESC) AS TopPostTitles
FROM TagRankedPosts rp
JOIN TagStatistics t ON rp.TagName = t.TagName
WHERE rp.TagPostRank <= 3 
GROUP BY t.TagName
ORDER BY TotalPostsUnderTag DESC, AverageScore DESC;
