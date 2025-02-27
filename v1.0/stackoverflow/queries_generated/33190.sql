WITH RecursivePosts AS (
    -- CTE to recursively find all the answers for a given question
    SELECT Id, ParentId, OwnerUserId, Score, CreationDate
    FROM Posts
    WHERE PostTypeId = 1 -- PostTypeId for Questions
    UNION ALL
    SELECT p.Id, p.ParentId, p.OwnerUserId, p.Score, p.CreationDate
    FROM Posts p
    INNER JOIN RecursivePosts rp ON rp.Id = p.ParentId
    WHERE p.PostTypeId = 2 -- PostTypeId for Answers
),
TagStatistics AS (
    -- CTE to summarize each tag's question and answer counts
    SELECT 
        t.TagName, 
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT a.Id) AS AnswerCount
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    LEFT JOIN Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    GROUP BY t.TagName
),
UserBadges AS (
    -- CTE to rank users based on their reputation and count badges
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        COUNT(b.Id) AS BadgeCount,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
PostHistoryEvents AS (
    -- CTE to find the last interaction with posts
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        LAG(ph.CreationDate) OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate) AS PreviousEventDate
    FROM PostHistory ph
),
ClosedPosts AS (
    -- CTE to find posts that have ever been closed and details about them
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS ClosedDate,
        u.DisplayName AS ClosedBy
    FROM Posts p
    JOIN PostHistoryEvents ph ON p.Id = ph.PostId
    JOIN Users u ON ph.UserId = u.Id
    WHERE ph.PostHistoryTypeId = 10 -- Post closed
)
SELECT 
    t.TagName, 
    ts.QuestionCount, 
    ts.AnswerCount,
    ub.Reputation, 
    ub.BadgeCount, 
    ph.ClosedDate,
    ph.ClosedBy,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId IN (SELECT PostId FROM RecursivePosts) AND v.VoteTypeId = 2) AS TotalUpvotes
FROM TagStatistics ts
JOIN Tags t ON ts.TagName = t.TagName
LEFT JOIN UserBadges ub ON ub.UserId = t.ExcerptPostId
LEFT JOIN ClosedPosts ph ON ph.PostId = t.WikiPostId
WHERE ts.QuestionCount > 0
ORDER BY ts.QuestionCount DESC, ts.AnswerCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY; -- Limit results to top 10
