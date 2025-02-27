
WITH RelevantPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.Tags, 
           p.CreationDate, 
           p.ViewCount, 
           u.DisplayName AS OwnerName,
           ph.Comment AS LastEditComment,
           ph.CreationDate AS LastEditDate,
           ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.PostTypeId = 1 
    AND ph.PostHistoryTypeId IN (4, 5, 6) 
),
LatestEdits AS (
    SELECT PostId, Title, Tags, CreationDate, ViewCount, OwnerName, LastEditComment, LastEditDate
    FROM RelevantPosts
    WHERE rn = 1
)
SELECT r.OwnerName, 
       COUNT(*) AS TotalQuestions, 
       AVG(TIMESTAMPDIFF(SECOND, r.CreationDate, '2024-10-01 12:34:56') / 3600) AS AvgHoursSinceCreated,
       SUM(r.ViewCount) AS TotalViewCount,
       GROUP_CONCAT(DISTINCT r.Title ORDER BY r.Title ASC SEPARATOR ', ') AS EditedTitles,
       GROUP_CONCAT(DISTINCT r.Tags ORDER BY r.Tags ASC SEPARATOR ', ') AS UniqueTags,
       COUNT(DISTINCT r.LastEditComment) AS DistinctEditComments
FROM LatestEdits r
GROUP BY r.OwnerName
ORDER BY TotalQuestions DESC
LIMIT 10;
