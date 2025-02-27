
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(p.Score, 0) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        CreationDate,
        OwnerDisplayName,
        AnswerCount,
        Score
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.AnswerCount,
    tp.Score,
    GROUP_CONCAT(DISTINCT UPPER(t.TagName) ORDER BY t.TagName SEPARATOR ', ') AS UniqueTags 
FROM 
    TopPosts tp
LEFT JOIN 
    (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(tp.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM 
            (SELECT @rownum := @rownum + 1 AS n FROM 
                (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
                UNION ALL SELECT 9 UNION ALL SELECT 10) numbers, 
                (SELECT @rownum := 0) r) numbers
        WHERE 
            n <= CHAR_LENGTH(tp.Tags) - CHAR_LENGTH(REPLACE(tp.Tags, '><', '')) + 1
    ) t ON TRUE
GROUP BY 
    tp.Title, tp.OwnerDisplayName, tp.AnswerCount, tp.Score
ORDER BY 
    tp.Score DESC, tp.AnswerCount DESC;
