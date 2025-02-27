WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.CreationDate, 
           COUNT(a.Id) AS AnswerCount,
           COUNT(DISTINCT c.Id) AS CommentCount,
           SUM(v.VoteTypeId = 2) AS UpVotes,  -- Only considering UpMod votes
           SUM(v.VoteTypeId = 3) AS DownVotes, -- Only considering DownMod votes
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2  -- Joining for answers
    LEFT JOIN Comments c ON p.Id = c.PostId  -- Joining for comments
    LEFT JOIN Votes v ON p.Id = v.PostId  -- Joining for votes
    WHERE p.PostTypeId = 1 -- Considering only Questions
    GROUP BY p.Id
),
TopUsers AS (
    SELECT u.Id AS UserId, 
           u.DisplayName,
           SUM(p.ViewCount) AS TotalViews,
           COUNT(DISTINCT p.Id) AS QuestionCount,
           SUM(rp.UpVotes) AS TotalUpVotes,
           SUM(rp.DownVotes) AS TotalDownVotes
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN RankedPosts rp ON p.Id = rp.Id
    GROUP BY u.Id
    HAVING COUNT(DISTINCT p.Id) > 0
    ORDER BY TotalViews DESC
    LIMIT 10
),
RecentEdits AS (
    SELECT ph.PostId, 
           MAX(ph.CreationDate) AS LastEditDate,
           COUNT(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 END) AS EditCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)  -- Changes to Title, Body, Tags
    GROUP BY ph.PostId
),
JoinedData AS (
    SELECT tu.UserId,
           tu.DisplayName,
           tu.TotalViews,
           tu.QuestionCount,
           re.LastEditDate,
           re.EditCount
    FROM TopUsers tu
    LEFT JOIN RecentEdits re ON tu.UserId = re.PostId
)
SELECT jd.UserId,
       jd.DisplayName,
       jd.TotalViews,
       jd.QuestionCount,
       COALESCE(jd.LastEditDate, 'No Edits') AS LastEditDate,
       COALESCE(jd.EditCount, 0) AS EditCount,
       CASE 
           WHEN jd.EditCount > 0 THEN 'Active Editor'
           ELSE 'No Edits Made'
       END AS EditorStatus
FROM JoinedData jd
ORDER BY jd.TotalViews DESC;
