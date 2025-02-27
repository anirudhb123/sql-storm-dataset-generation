WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        u.DisplayName AS AuthorDisplayName,
        u.Reputation AS AuthorReputation,
        ph.UserDisplayName AS LastEditor,
        ph.CreationDate AS LastEditDate,
        COALESCE(ah.Id, 0) AS AcceptedAnswerId,
        COALESCE(ph.Comment, '') AS LastEditComment
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts ah ON p.AcceptedAnswerId = ah.Id
    LEFT JOIN 
        PostHistory ph ON p.LastEditorUserId = ph.UserId AND ph.PostId = p.Id
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_array ON t.TagName IN (SELECT TagName FROM Tags WHERE Id = CAST(FROM_UNNEST(tag_array) AS int))
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation, ph.UserDisplayName, ph.CreationDate, ah.Id
),
BenchmarkStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore,
        COUNT(DISTINCT AuthorDisplayName) AS UniqueAuthors,
        COUNT(DISTINCT Tags) AS UniqueTags
    FROM 
        PostDetails
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.Tags,
    pd.AuthorDisplayName,
    pd.AuthorReputation,
    pd.LastEditor,
    pd.LastEditDate,
    pd.LastEditComment,
    bs.TotalPosts,
    bs.AvgViewCount,
    bs.AvgScore,
    bs.UniqueAuthors,
    bs.UniqueTags
FROM 
    PostDetails pd,
    BenchmarkStats bs
WHERE 
    pd.ViewCount > bs.AvgViewCount
ORDER BY 
    pd.ViewCount DESC, pd.CreationDate DESC
LIMIT 100;
