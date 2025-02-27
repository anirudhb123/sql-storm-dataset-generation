WITH RecursivePostHierarchy AS (
    -- CTE to find all answers for each question and their associated users.
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.OwnerUserId,
        p.Title,
        1 AS Depth
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.OwnerUserId,
        p.Title,
        Depth + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId  
    WHERE p.PostTypeId = 2  -- Answers
),
AggregatedPostInfo AS (
    -- CTE to aggregate post information including scores and tags
    SELECT 
        r.PostId,
        COUNT(r.PostId) FILTER (WHERE r.Depth = 1) AS AnswerCount,  -- Count of direct answers
        SUM(v.VoteTypeId = 2) AS UpVoteCount,   -- Summing upvotes
        SUM(v.VoteTypeId = 3) AS DownVoteCount, -- Summing downvotes
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM RecursivePostHierarchy r
    LEFT JOIN Votes v ON r.PostId = v.PostId
    LEFT JOIN UNNEST(string_to_array((SELECT Tags FROM Posts WHERE Id = r.PostId), ',')) AS t(TagName)
    GROUP BY r.PostId
),
PostHistoryDetails AS (
    -- CTE to get relevant post history types and comments
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE ph.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for recent changes
),
UserReputation AS (
    -- CTE to calculate average reputation of users interacting with posts.
    SELECT 
        p.OwnerUserId,
        AVG(u.Reputation) AS AvgReputation
    FROM Posts p
    INNER JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.OwnerUserId IS NOT NULL
    GROUP BY p.OwnerUserId
)

SELECT 
    p.Title,
    COALESCE(pi.AnswerCount, 0) AS TotalAnswers,
    COALESCE(pi.UpVoteCount, 0) AS TotalUpVotes,
    COALESCE(pi.DownVoteCount, 0) AS TotalDownVotes,
    ARRAY_AGG(DISTINCT ph.Comment) AS RecentComments,
    ur.AvgReputation
FROM Posts p
LEFT JOIN AggregatedPostInfo pi ON p.Id = pi.PostId
LEFT JOIN PostHistoryDetails ph ON p.Id = ph.PostId
LEFT JOIN UserReputation ur ON p.OwnerUserId = ur.OwnerUserId
WHERE p.PostTypeId = 1  -- Only include questions
GROUP BY p.Id, ur.AvgReputation
ORDER BY TotalAnswers DESC, TotalUpVotes DESC;
