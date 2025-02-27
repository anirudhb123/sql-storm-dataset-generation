WITH RecursivePostHistory AS (
    SELECT p.Id AS PostId,
           p.Title,
           ph.CreationDate,
           ph.PostHistoryTypeId,
           ph.UserDisplayName,
           ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId IN (1, 2, 4, 6)  -- Initial title, body changes, title edits, tag edits
),
TopPosts AS (
    SELECT p.Id,
           p.Title,
           p.OwnerUserId,
           p.Score,
           p.ViewCount,
           COALESCE(c.CommentCount, 0) AS CommentCount,
           COALESCE(a.AcceptedAnswerCount, 0) AS AcceptedAnswerCount,
           RANK() OVER (ORDER BY p.Score DESC) AS RankByScore
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT ParentId, COUNT(*) AS AcceptedAnswerCount
        FROM Posts
        WHERE PostTypeId = 2 AND AcceptedAnswerId IS NOT NULL
        GROUP BY ParentId
    ) a ON p.Id = a.ParentId
    WHERE p.PostTypeId = 1  -- Only questions
    AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  -- Last year
)
SELECT TOP 10
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    rp.UserDisplayName AS LastEditor,
    rp.CreationDate AS LastEditDate,
    rp.PostHistoryTypeId,
    CASE 
        WHEN rp.PostHistoryTypeId IS NOT NULL THEN 'Edited'
        ELSE 'No Edits'
    END AS EditStatus
FROM TopPosts tp
LEFT JOIN RecursivePostHistory rp ON tp.Id = rp.PostId AND rp.HistoryRank = 1  -- Latest edit for each post
WHERE tp.RankByScore <= 10
ORDER BY tp.Score DESC;

-- Additional metrics related to user activities
SELECT u.Id AS UserId,
       u.DisplayName,
       SUM(b.Count) AS TotalBadges,
       SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
       SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
       AVG(p.Score) AS AveragePostScore
FROM Users u
LEFT JOIN Badges b ON u.Id = b.UserId
LEFT JOIN Votes v ON u.Id = v.UserId
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
GROUP BY u.Id, u.DisplayName
ORDER BY TotalBadges DESC, AveragePostScore DESC;

-- Combining analyses with UNION ALL
SELECT 
    'Top Posts' AS Category,
    Title,
    Score,
    NULL AS UserId,
    ViewCount
FROM TopPosts

UNION ALL

SELECT 
    'User Engagement' AS Category,
    DisplayName AS Title,
    TotalBadges AS Score,
    UserId,
    NULL AS ViewCount
FROM (
    SELECT u.DisplayName,
           u.Id AS UserId,
           COUNT(b.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.DisplayName, u.Id
) x
ORDER BY Score DESC;
