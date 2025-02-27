
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COALESCE(CONCAT(CAST(b.Class AS CHAR), ' ', b.Name), 'No Badges') AS UserBadges
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    INNER JOIN 
    (
        SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    ) numbers ON LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
),

QuestionSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Score,
        rp.OwnerDisplayName,
        GROUP_CONCAT(pt.Tag ORDER BY pt.Tag SEPARATOR ', ') AS Tags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostTags pt ON rp.PostId = pt.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.AnswerCount, rp.Score, rp.OwnerDisplayName
)

SELECT 
    qs.PostId,
    qs.Title,
    qs.CreationDate,
    qs.ViewCount,
    qs.AnswerCount,
    qs.Score,
    qs.OwnerDisplayName,
    qs.Tags,
    CASE 
        WHEN qs.Score >= 10 THEN 'Highly Rated'
        WHEN qs.Score BETWEEN 5 AND 9 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS RatingCategory
FROM 
    QuestionSummary qs
ORDER BY 
    qs.Score DESC, 
    qs.ViewCount DESC
LIMIT 50;
