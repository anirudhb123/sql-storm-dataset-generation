WITH RECURSIVE PostHierarchy AS (
    SELECT Id, Title, OwnerUserId, ParentId, 1 AS Level
    FROM Posts
    WHERE ParentId IS NULL  -- Selecting top-level questions
    
    UNION ALL
    
    SELECT p.Id, p.Title, p.OwnerUserId, p.ParentId, ph.Level + 1
    FROM Posts p
    JOIN PostHierarchy ph ON p.ParentId = ph.Id  -- Joining to get answers under questions 
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBountyWon 
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Bounty Start and Bounty Close
    GROUP BY u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        ph.Level,
        p.CreationDate,
        p.Score,
        RANK() OVER (PARTITION BY ph.Level ORDER BY p.Score DESC) AS ScoreRank
    FROM Posts p
    JOIN PostHierarchy ph ON p.ParentId = ph.Id 
    WHERE p.Score > 0  -- Only considering popular posts
),
RecentVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount  -- Downvotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > NOW() - INTERVAL '30 days'  -- Votes from the last 30 days
    GROUP BY p.Id
)
SELECT 
    u.DisplayName AS User,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(COALESCE(r.VoteCount, 0)) AS RecentVotes,
    SUM(COALESCE(r.DownVoteCount, 0)) AS RecentDownVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    STRING_AGG(DISTINCT pp.Title || ' (Score: ' || pp.Score || ')', '; ') AS PopularAnswers
FROM UserActivity u
LEFT JOIN Posts p ON u.UserId = p.OwnerUserId
LEFT JOIN RecentVotes r ON p.Id = r.PostId
LEFT JOIN LATERAL (
    SELECT pp.Title, pp.Score
    FROM PopularPosts pp
    WHERE pp.OwnerUserId = u.UserId
) pp ON TRUE
LEFT JOIN UNNEST(string_to_array(p.Tags, '>')) AS t(TagName)
WHERE p.PostTypeId = 1 -- Selecting only questions
GROUP BY u.UserId, u.DisplayName
HAVING COUNT(DISTINCT p.Id) > 5
ORDER BY TotalPosts DESC, RecentVotes DESC;
