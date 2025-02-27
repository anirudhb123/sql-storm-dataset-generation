
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
        AND p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56') 
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
        value AS Tag,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveVotes
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, ',') 
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        value
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
    TopRanked tp ON tp.Title LIKE '%' + tt.Tag + '%' 
WHERE 
    tt.TagRank <= 5 
ORDER BY 
    tt.PostCount DESC, 
    tp.Score DESC;
