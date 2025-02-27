WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    t.TagName,
    COUNT(tp.Id) AS PostCount,
    SUM(tp.Score) AS TotalScore,
    AVG(tp.ViewCount) AS AverageViews,
    AVG(tp.AnswerCount) AS AverageAnswers
FROM 
    TopPosts tp
JOIN 
    STRING_TO_ARRAY(tp.Tags, ',') AS tags ON TRUE
JOIN 
    Tags t ON t.TagName = TRIM(tags)
GROUP BY 
    t.TagName
ORDER BY 
    TotalScore DESC
LIMIT 10;
