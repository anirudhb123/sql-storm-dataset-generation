WITH RankedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
AggPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TagUsage
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    HAVING COUNT(p.Id) > 10
),
ActivePosts AS (
    SELECT 
        p.Id,
        COALESCE(ah.Id, 0) AS AcceptedAnswerId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentsCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes
    FROM Posts p
    LEFT JOIN Posts ah ON p.AcceptedAnswerId = ah.Id
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE p.LastActivityDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id, ah.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    aps.TotalPosts,
    aps.Questions,
    aps.Answers,
    aps.TotalScore,
    (SELECT STRING_AGG(tt.TagName, ', ') 
        FROM TopTags tt) AS CommonTags,
    COUNT(ap.Id) AS ActivePostsCount,
    SUM(ap.Upvotes) AS TotalUpvotes,
    SUM(ap.Downvotes) AS TotalDownvotes,
    CASE 
        WHEN upvotes > downvotes THEN 'More Upvotes'
        WHEN upvotes < downvotes THEN 'More Downvotes'
        ELSE 'Equal Voting'
    END AS VotingTrend
FROM RankedUsers u
JOIN AggPostStats aps ON u.Id = aps.OwnerUserId
LEFT JOIN ActivePosts ap ON ap.OwnerUserId = u.Id
GROUP BY u.Id, aps.TotalPosts, aps.Questions, aps.Answers, aps.TotalScore
ORDER BY u.Reputation DESC, ActivePostsCount DESC
FETCH FIRST 10 ROWS ONLY;

-- Additional mystery section for obscurity (some unusual semantics):
SELECT 
    COALESCE((SELECT Name FROM VoteTypes WHERE Id = 1), 'N/A') AS VoteType,
    (SELECT STRING_AGG(DISTINCT Name, ', ') 
        FROM LinkTypes
        WHERE Id NOT IN (SELECT LinkTypeId FROM PostLinks WHERE PostId = ANY (SELECT Id FROM Posts))) AS UnusedLinkTypes,
    CASE 
        WHEN 'a' IS NULL THEN 'NULL Logic' 
        ELSE 'No NULL Logic' 
    END AS NullTest,
    p.Title AS ExamplePostTitle
FROM Posts p
WHERE p.Id IN (SELECT DISTINCT PostId FROM Comments WHERE Text IS NOT NULL)
ORDER BY RANDOM()
LIMIT 5;

-- Note: 
-- 1. Ensure correct indexing for performance during testing.
-- 2. Analyze using EXPLAIN for understanding execution plan.
