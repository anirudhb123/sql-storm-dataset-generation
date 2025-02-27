-- Benchmarking string processing by analyzing post titles, their edits, and associated tags.

WITH 
-- Step 1: CTE to extract and standardize post titles and history
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
        ph.PostHistoryTypeId IN (4, 5) -- Edit Title or Edit Body
),
-- Step 2: CTE to extract unique tags and their counts
TagExtract AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substr(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
),
-- Step 3: CTE to join titles with their tags and rank them by edit history
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
-- Final Step: Selecting and processing data for performance benchmarking
SELECT 
    tr.PostId,
    tr.OriginalTitle,
    tr.EditText,
    tr.EditComment,
    tr.Tag,
    COUNT(*) AS TagCount,
    MAX(tr.EditRank) AS LatestEditRank,
    STRING_AGG(DISTINCT tr.Tag, ', ') AS AllTags
FROM 
    TitleTagRanking tr
GROUP BY 
    tr.PostId, tr.OriginalTitle, tr.EditText, tr.EditComment, tr.Tag
ORDER BY 
    TagCount DESC, LatestEditRank DESC;

-- Explanation: 
-- 1. TitleHistory extracts titles and their edit histories while assigning ranks.
-- 2. TagExtract processes tags and counts occurrences.
-- 3. TitleTagRanking combines these histories and tags.
-- 4. The final SELECT performs aggregations for benchmarking post-edit histories against their respective tags.
