
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
        COALESCE(CONCAT(CAST(b.Class AS VARCHAR), ' ', b.Name), 'No Badges') AS UserBadges
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TO_TIMESTAMP('2024-10-01 12:34:56') - INTERVAL '1 year' 
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        TRIM(REGEXP_SUBSTR(p.Tags, '[^><]+', 1, seq)) AS Tag
    FROM 
        Posts p,
        TABLE(GENERATOR(ROWCOUNT => 100)) seq
    WHERE 
        seq <= REGEXP_COUNT(p.Tags, '><') + 1
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
        LISTAGG(pt.Tag, ', ') AS Tags
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
