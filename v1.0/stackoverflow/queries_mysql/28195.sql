
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        GROUP_CONCAT(DISTINCT t.TagName) AS TagsArray,
        COALESCE(SUM(CASE WHEN pt.Id IN (1, 2) THEN 1 ELSE 0 END), 0) AS PostVoteCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (SELECT TRIM(BOTH '>' FROM TRIM(BOTH '<' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<', numbers.n), '>', -1))) AS tag
                FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
                WHERE numbers.n <= (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '>', '')))) AS tag ON TRUE
    LEFT JOIN Tags t ON t.TagName = tag
    LEFT JOIN Votes pt ON pt.PostId = p.Id
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName AS EditorDisplayName,
        ph.Comment AS EditComment,
        @row_number := IF(@current_post_id = ph.PostId, @row_number + 1, 1) AS HistoryRowNum,
        @current_post_id := ph.PostId
    FROM PostHistory ph, (SELECT @row_number := 0, @current_post_id := NULL) AS vars
    ORDER BY ph.PostId, ph.CreationDate DESC
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.CreationDate,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.OwnerDisplayName,
    pd.TagsArray,
    pd.PostVoteCount,
    COALESCE(phd.HistoryRowNum, 0) AS LastEditVersion,
    COALESCE(phd.EditorDisplayName, 'No edits made') AS LastEditor,
    COALESCE(phd.HistoryDate, NULL) AS LastEditDate,
    COALESCE(phd.EditComment, 'N/A') AS LastEditComment
FROM PostDetails pd
LEFT JOIN PostHistoryDetails phd ON pd.PostId = phd.PostId AND phd.HistoryRowNum = 1
WHERE pd.PostVoteCount > 0
ORDER BY pd.ViewCount DESC, pd.CreationDate DESC
LIMIT 50;
