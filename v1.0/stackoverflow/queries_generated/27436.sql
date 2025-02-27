WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Tags,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           COALESCE(a.Title, 'No Accepted Answer') AS AcceptedAnswerTitle,
           COALESCE(a.Id, -1) AS AcceptedAnswerId,
           ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    LEFT JOIN Posts a ON p.AcceptedAnswerId = a.Id
    WHERE p.PostTypeId = 1  -- Selecting only Questions
),
TagCount AS (
    SELECT UNNEST(string_to_array(Tags, '>')) AS TagName,
           COUNT(*) AS Count
    FROM Posts
    WHERE PostTypeId = 1
    GROUP BY TagName
),
TopActiveUsers AS (
    SELECT u.DisplayName,
           SUM(u.UpVotes) AS TotalUpVotes,
           SUM(u.DownVotes) AS TotalDownVotes,
           COUNT(DISTINCT p.Id) AS PostsCount
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.DisplayName
    ORDER BY TotalUpVotes DESC
    LIMIT 10
),
RecentPostEditHistory AS (
    SELECT ph.PostId,
           ph.UserDisplayName,
           ph.CreationDate,
           ph.Comment,
           ph.Text
    FROM PostHistory ph
    INNER JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Edit Body, Edit Tags
    ORDER BY ph.CreationDate DESC
)
SELECT rp.PostId,
       rp.Title,
       rp.AcceptedAnswerTitle,
       rp.CreationDate,
       rp.Score,
       rp.ViewCount,
       tc.TagName,
       tc.Count AS TagFrequency,
       tau.DisplayName AS ActiveUser,
       tau.PostsCount,
       rpe.UserDisplayName AS LastEditor,
       rpe.CreationDate AS LastEditDate,
       rpe.Comment AS EditComment,
       rpe.Text AS NewText
FROM RankedPosts rp
LEFT JOIN TagCount tc ON rp.Tags LIKE '%' || tc.TagName || '%'
LEFT JOIN TopActiveUsers tau ON rp.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = tau.Id)
LEFT JOIN RecentPostEditHistory rpe ON rp.PostId = rpe.PostId
WHERE tc.Count IS NOT NULL
ORDER BY rp.Score DESC, rp.ViewCount DESC;
