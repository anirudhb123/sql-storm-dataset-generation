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
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Questions from the last year
        AND p.Body IS NOT NULL -- Exclude empty bodies
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
        rp.Rank <= 3 -- Top 3 posts per tag
),
TagStats AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS Tag,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveVotes
    FROM 
        Posts p
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
        PostCount > 5 -- Only tags with more than 5 questions
)

SELECT 
    t.Tag,
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
    TopRanked tp ON tp.Title ILIKE '%' || tt.Tag || '%' -- Match title to Tag
WHERE 
    tt.TagRank <= 5 -- Top 5 tags
ORDER BY 
    tt.PostCount DESC, 
    tp.Score DESC;
