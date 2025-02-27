WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)
),
TopRatedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostAggregates AS (
    SELECT 
        t.TagName,
        COUNT(tp.PostId) AS PostCount,
        SUM(tp.Score) AS TotalScore,
        AVG(tp.ViewCount) AS AverageViews,
        AVG(tp.AnswerCount) AS AverageAnswers
    FROM 
        TopRatedPosts tp
    JOIN 
        UNNEST(string_to_array(tp.Tags, '><')) AS t(TagName) ON TRUE
    GROUP BY 
        t.TagName
)
SELECT 
    pa.TagName,
    pa.PostCount,
    pa.TotalScore,
    pa.AverageViews,
    pa.AverageAnswers
FROM 
    PostAggregates pa
ORDER BY 
    pa.TotalScore DESC
LIMIT 10;
