WITH RecursivePostHierarchy AS (
    -- CTE to create a hierarchy of posts and their answers
    SELECT 
        Id,
        ParentId,
        Title,
        Score,
        CreationDate,
        0 AS Level
    FROM Posts
    WHERE ParentId IS NULL  -- Starting with questions only

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.Score,
        p.CreationDate,
        Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
UserRankings AS (
    -- CTE to rank users based on their reputation and total answers posted
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(a.Id) AS TotalAnswers,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    LEFT JOIN Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2  -- Answers only
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
RecentPostHistory AS (
    -- CTE to aggregate recent post histories and join with corresponding users
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        u.DisplayName AS UserDisplayName,
        STRING_AGG(DISTINCT h.Name, ', ') AS HistoryTypes
    FROM PostHistory ph
    JOIN Users u ON ph.UserId = u.Id
    JOIN PostHistoryTypes h ON ph.PostHistoryTypeId = h.Id
    WHERE ph.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY ph.PostId, ph.UserId, ph.PostHistoryTypeId, ph.CreationDate, u.DisplayName
),
QuestionStats AS (
    -- CTE to compute statistics for questions
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,  -- Count of upvotes
        SUM(v.VoteTypeId = 3) AS DownVotes,  -- Count of downvotes
        COALESCE(MAX(ph.CreationDate), p.CreationDate) AS LastActivityDate
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId  -- Join on answers
    LEFT JOIN Comments c ON p.Id = c.PostId  -- Join on comments
    LEFT JOIN Votes v ON p.Id = v.PostId  -- Join on votes
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId  -- Join on post history
    WHERE p.PostTypeId = 1  -- Only questions
    GROUP BY p.Id
)
-- Final Query: Combine all previous CTEs to get a comprehensive view
SELECT 
    qs.QuestionId,
    qs.Title,
    qs.AnswerCount,
    qs.CommentCount,
    qs.UpVotes,
    qs.DownVotes,
    RPH.id AS RelatedAnswerId,
    U.DisplayName AS AnswerOwner,
    U.Reputation AS AnswerOwnerReputation,
    U.TotalAnswers AS AnswerOwnerTotalAnswers,
    RPHC.Level AS HierarchyLevel,
    RPHC.Title AS ParentPostTitle,
    RPHC.Score AS ParentPostScore,
    RPHC.CreationDate AS ParentPostCreationDate,
    RPH.Rank AS UserReputationRank,
    RPHC.LastActivityDate AS ParentPostLastActivity
FROM QuestionStats qs
LEFT JOIN RecursivePostHierarchy RPHC ON qs.QuestionId = RPHC.ParentId
LEFT JOIN UserRankings U ON RPHC.OwnerUserId = U.UserId
WHERE qs.UpVotes > qs.DownVotes  -- Filter for questions with more upvotes than downvotes
ORDER BY qs.LastActivityDate DESC, RPHC.Score DESC;
