
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
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT n FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n) n
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
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
    GROUP_CONCAT(DISTINCT tr.Tag ORDER BY tr.Tag SEPARATOR ', ') AS AllTags
FROM 
    TitleTagRanking tr
GROUP BY 
    tr.PostId, tr.OriginalTitle, tr.EditText, tr.EditComment, tr.Tag
ORDER BY 
    TagCount DESC, LatestEditRank DESC;
