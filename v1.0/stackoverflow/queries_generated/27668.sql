WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Body,
           COALESCE(CAST(NULLIF(p.AcceptedAnswerId, -1) AS int), 0) AS AcceptedAnswer,
           u.DisplayName AS OwnerDisplayName,
           p.CreationDate,
           p.LastActivityDate,
           ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN STRING_TO_ARRAY(p.Tags, ',') AS tag_array ON true
    LEFT JOIN Tags t ON t.TagName = TRIM(BOTH '"' FROM tag_array)
    WHERE p.PostTypeId = 1 -- Only questions
    GROUP BY p.Id, p.Title, p.Body, p.AcceptedAnswerId, u.DisplayName, p.CreationDate, p.LastActivityDate
),
PostHistoryEvents AS (
    SELECT ph.PostId,
           ph.UserDisplayName,
           ph.PostHistoryTypeId,
           ph.CreationDate,
           cnt.Id AS BadgeId,
           cnt.Name AS BadgeName
    FROM PostHistory ph
    LEFT JOIN Badges cnt ON cnt.UserId = ph.UserId
    WHERE ph.CreationDate > NOW() - INTERVAL '1 year'
    AND ph.PostHistoryTypeId IN (10, 11, 12, 37) -- Closed, Reopened, Deleted, Merged
),
Stats AS (
    SELECT rp.PostId,
           COUNT(DISTINCT phe.UserDisplayName) AS UniqueUsersInvolved,
           COUNT(phe.PostHistoryTypeId) AS EventCount
    FROM RankedPosts rp
    LEFT JOIN PostHistoryEvents phe ON rp.PostId = phe.PostId
    GROUP BY rp.PostId
)

SELECT rp.PostId,
       rp.Title,
       rp.OwnerDisplayName,
       rp.CreationDate,
       rp.LastActivityDate,
       rp.AcceptedAnswer,
       rp.Tags,
       COALESCE(s.UniqueUsersInvolved, 0) AS UniqueUserInvolvement,
       COALESCE(s.EventCount, 0) AS HistoricalEventCount,
       CASE 
           WHEN rp.LastActivityDate < NOW() - INTERVAL '6 months' THEN 'Inactive'
           WHEN rp.LastActivityDate >= NOW() - INTERVAL '6 months' AND rp.LastActivityDate < NOW() - INTERVAL '1 month' THEN 'Low Activity'
           WHEN rp.LastActivityDate >= NOW() - INTERVAL '1 month' THEN 'Active'
       END AS ActivityStatus
FROM RankedPosts rp
LEFT JOIN Stats s ON rp.PostId = s.PostId
ORDER BY rp.CreationDate DESC
LIMIT 100;
