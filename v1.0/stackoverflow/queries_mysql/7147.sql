
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount, u.DisplayName, p.PostTypeId
),
HighScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Author,
        rp.RankScore,
        rp.CommentCount
    FROM RankedPosts rp
    WHERE rp.RankScore <= 10
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', numbers.n), '<>', -1) AS TagName
        FROM 
            Posts p
        INNER JOIN (
            SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL
            SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL
            SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL
            SELECT 10
        ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '<>', '')) >= numbers.n - 1
    ) t ON p.Id = t.PostId
    GROUP BY p.Id
)
SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.Score,
    hsp.ViewCount,
    hsp.AnswerCount,
    hsp.Author,
    hsp.CommentCount,
    pt.Tags
FROM HighScoringPosts hsp
JOIN PostTags pt ON hsp.PostId = pt.PostId
ORDER BY hsp.Score DESC, hsp.ViewCount DESC;
