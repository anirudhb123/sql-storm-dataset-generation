
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
), CloseStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseReasonsCount,
        GROUP_CONCAT(crt.Name ORDER BY crt.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS UNSIGNED) = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
), TopTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS TagName
    FROM 
        RankedPosts
    INNER JOIN (
        SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    WHERE 
        TagRank = 1 
)
SELECT 
    rp.Title AS QuestionTitle,
    rp.Author,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ct.CloseReasonsCount,
    ct.CloseReasons,
    tt.TagName
FROM 
    RankedPosts rp
LEFT JOIN 
    CloseStats ct ON rp.PostId = ct.PostId
JOIN 
    TopTags tt ON tt.TagName = rp.Tags
WHERE 
    rp.TagRank = 1
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC
LIMIT 10;
