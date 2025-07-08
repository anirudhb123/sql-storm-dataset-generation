
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        GREATEST(COALESCE(p.Score, 0), COALESCE(p.ViewCount, 0) / 10) AS Popularity,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY GREATEST(COALESCE(p.Score, 0), COALESCE(p.ViewCount, 0) / 10) DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > DATEADD(YEAR, -1, '2024-10-01 12:34:56')
),

TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Tags t
    JOIN 
        Posts p ON POSITION(t.TagName IN p.Tags) > 0
    GROUP BY 
        t.TagName
),

FilteredComments AS (
    SELECT 
        c.PostId,
        LISTAGG(c.Text, ' ') AS AllComments,
        COUNT(*) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate > DATEADD(MONTH, -6, '2024-10-01 12:34:56')
    GROUP BY 
        c.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.AnswerCount,
    tc.CommentCount AS TotalComments,
    tc.AllComments,
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.TotalScore
FROM 
    RankedPosts rp
LEFT JOIN 
    FilteredComments tc ON rp.PostId = tc.PostId
LEFT JOIN 
    TagStats ts ON POSITION(ts.TagName IN rp.Tags) > 0
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Popularity DESC, rp.CreationDate DESC;
