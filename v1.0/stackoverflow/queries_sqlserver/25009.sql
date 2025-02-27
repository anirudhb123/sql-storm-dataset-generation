
WITH 

TitleHistory AS (
    SELECT 
        ph.PostId, 
        ph.UserId, 
        ph.CreationDate,
        ph.Text AS EditText,
        COALESCE(ph.Comment, 'No comment') AS EditComment,
        (SELECT Title FROM Posts WHERE Id = ph.PostId) AS OriginalTitle,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) 
),

TagExtract AS (
    SELECT 
        p.Id AS PostId,
        value AS Tag
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS value
    WHERE 
        p.Tags IS NOT NULL
),

TitleTagRanking AS (
    SELECT 
        th.PostId,
        th.OriginalTitle,
        th.EditText,
        th.EditComment,
        tg.Tag,
        th.EditRank
    FROM 
        TitleHistory th
    JOIN 
        TagExtract tg ON th.PostId = tg.PostId
)

SELECT 
    tr.PostId,
    tr.OriginalTitle,
    tr.EditText,
    tr.EditComment,
    tr.Tag,
    COUNT(*) AS TagCount,
    MAX(tr.EditRank) AS LatestEditRank,
    STRING_AGG(tr.Tag, ', ') WITHIN GROUP (ORDER BY tr.Tag) AS AllTags
FROM 
    TitleTagRanking tr
GROUP BY 
    tr.PostId, tr.OriginalTitle, tr.EditText, tr.EditComment, tr.Tag
ORDER BY 
    TagCount DESC, LatestEditRank DESC;
