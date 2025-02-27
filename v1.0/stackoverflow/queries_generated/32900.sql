WITH RecursivePosts AS (
    -- Recursive CTE to collect all posts related to the top-level questions
    SELECT p.Id AS PostId, p.Title, p.OwnerUserId, p.CreationDate, 1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Questions

    UNION ALL

    SELECT p.Id, p.Title, p.OwnerUserId, p.CreationDate, rp.Level + 1
    FROM Posts p
    INNER JOIN RecursivePosts rp ON p.ParentId = rp.PostId
),
UserVoteStats AS (
    -- Aggregate votes for each user that posted questions
    SELECT u.Id AS UserId,
           u.DisplayName,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           COUNT(DISTINCT p.Id) AS QuestionCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
PostMetrics AS (
    -- Gather metrics for each post including views and answer counts
    SELECT p.Id,
           p.Title,
           p.ViewCount,
           COALESCE(p.AnswerCount, 0) AS AnswerCount,
           COALESCE(u.DisplayName, 'Community User') AS Owner,
           p.LastActivityDate
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
),
CombinedStats AS (
    -- Combine stats from recursive CTE and other metrics
    SELECT rp.PostId,
           rp.Title,
           rp.CreationDate,
           uvs.DisplayName AS UserDisplayName,
           COALESCE(uvs.UpVotes, 0) AS UserUpVotes,
           COALESCE(uvs.DownVotes, 0) AS UserDownVotes,
           pm.ViewCount,
           pm.AnswerCount,
           pm.Owner
    FROM RecursivePosts rp
    LEFT JOIN UserVoteStats uvs ON rp.OwnerUserId = uvs.UserId
    LEFT JOIN PostMetrics pm ON rp.PostId = pm.Id
)
-- Final Select to display results with criteria
SELECT cs.PostId,
       cs.Title,
       cs.UserDisplayName,
       cs.UserUpVotes,
       cs.UserDownVotes,
       cs.ViewCount,
       cs.AnswerCount,
       CASE 
           WHEN cs.UserUpVotes > cs.UserDownVotes THEN 'Positive'
           WHEN cs.UserDownVotes > cs.UserUpVotes THEN 'Negative'
           ELSE 'Neutral'
       END AS VoteSentiment,
       date_part('year', cs.CreationDate) AS PostYear
FROM CombinedStats cs
WHERE cs.ViewCount > 50
ORDER BY cs.ViewCount DESC;
