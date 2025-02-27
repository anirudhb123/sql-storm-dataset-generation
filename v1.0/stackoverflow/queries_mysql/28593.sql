
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN p.AnswerCount > 0 THEN 'Answerable'
            ELSE 'Unanswered'
        END AS Answerability
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= (NOW() - INTERVAL 1 YEAR) 
        AND p.Body IS NOT NULL 
),
TopRanked AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        rp.Answerability
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 3 
),
TagStats AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS Tag,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveVotes
    FROM 
        Posts p
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 
         UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - 
         CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        PositiveVotes,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStats
    WHERE 
        PostCount > 5 
)

SELECT 
    tt.Tag,
    tt.PostCount,
    tt.PositiveVotes,
    tp.Title,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.Score,
    tp.Answerability
FROM 
    TopTags tt
JOIN 
    TopRanked tp ON tp.Title LIKE CONCAT('%', tt.Tag, '%') 
WHERE 
    tt.TagRank <= 5 
ORDER BY 
    tt.PostCount DESC, 
    tp.Score DESC;
