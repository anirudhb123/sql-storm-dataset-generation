WITH RecursivePostCTE AS (
    -- Recursive Common Table Expression to get post ancestry for answers
    SELECT p.Id AS PostId, p.ParentId, 1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 2  -- Answers

    UNION ALL

    SELECT p.Id AS PostId, p.ParentId, Level + 1 
    FROM Posts p
    INNER JOIN RecursivePostCTE r ON p.Id = r.ParentId
),

UserActivity AS (
    -- Weekly user activity with a rank on the number of posts made
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank,
        SUM(CASE WHEN p.CreationDate >= NOW() - INTERVAL '1 week' THEN 1 ELSE 0 END) AS PostsLastWeek
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),

PostStatistics AS (
    -- Aggregation of posts and their corresponding metrics
    SELECT
      p.Id,
      p.Title,
      p.CreationDate,
      COUNT(c.Id) AS CommentCount,
      SUM(v.VoteTypeId = 2) AS TotalUpVotes,
      SUM(v.VoteTypeId = 3) AS TotalDownVotes,
      STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN LATERAL (
        SELECT unnest(string_to_array(p.Tags, '><')) AS TagName
    ) t ON TRUE
    WHERE p.PostTypeId = 1  -- Questions
    GROUP BY p.Id, p.Title, p.CreationDate
),

PostHistoryStats AS (
    -- Finding posts with the most edit activity
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)  -- Edits related to title, body, tags
    GROUP BY ph.PostId
)

SELECT 
    u.DisplayName AS UserName,
    ps.Title AS QuestionTitle,
    ps.CreationDate AS QuestionDate,
    ps.CommentCount,
    ps.TotalUpVotes,
    ps.TotalDownVotes,
    phs.EditCount AS EditActivityCount,
    ha.PostId AS AnswerId,
    ha.Level AS AnswerLevel,
    ha.ParentId AS ParentAnswerId,
    ua.TotalPosts AS TotalUserPosts,
    ua.PostRank AS UserPostRank,
    CASE WHEN ua.PostsLastWeek > 0 THEN 'Active' ELSE 'Inactive' END AS UserStatus
FROM PostStatistics ps
LEFT JOIN RecursivePostCTE ha ON ps.Id = ha.ParentId
LEFT JOIN PostHistoryStats phs ON ps.Id = phs.PostId
LEFT JOIN UserActivity ua ON ps.OwnerUserId = ua.UserId
JOIN Users u ON ps.OwnerUserId = u.Id
WHERE ps.CommentCount > 10  -- Filter for posts with meaningful interactions
ORDER BY UserPostRank, CommentCount DESC;
