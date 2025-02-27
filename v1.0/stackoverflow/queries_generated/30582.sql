WITH RecursivePostCTE AS (
    -- This CTE retrieves all posts, along with their respective accepted answers if available.
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Questions only

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        Level + 1
    FROM Posts p
    JOIN RecursivePostCTE r ON p.ParentId = r.PostId
    WHERE p.PostTypeId = 2 -- Answers only
),

UserActivity AS (
    -- This CTE calculates the activity score for users based on various actions performed.
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(COUNT(DISTINCT p.Id), 0) AS TotalPosts,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId 
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)

SELECT 
    u.DisplayName AS UserName,
    ua.TotalPosts,
    ua.TotalBounty,
    ua.TotalBadges,
    u.Reputation,
    COALESCE(MAX(r.Score), 0) AS MaxScore,
    
    -- Generating a concatenated list of tag names from posts authored by the user
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    
    -- Checking for null on accepted answerId
    CASE 
        WHEN COUNT(r.AcceptedAnswerId) > 0 THEN 'Has Accepted Answers'
        ELSE 'No Accepted Answers'
    END AS AnswerStatus
FROM UserActivity ua
JOIN Users u ON ua.UserId = u.Id
LEFT JOIN RecursivePostCTE r ON u.Id = r.OwnerUserId
LEFT JOIN Posts p ON r.PostId = p.Id
LEFT JOIN Tags t ON POSITION(CONCAT('<', t.TagName, '>') IN p.Tags) > 0
GROUP BY u.DisplayName, ua.TotalPosts, ua.TotalBounty, ua.TotalBadges, u.Reputation
ORDER BY ua.TotalPosts DESC, u.Reputation DESC;

-- The above query aggregates user data with posts, votes, and badges,
-- while also incorporating recursive post relationships and string aggregation
-- for effective performance benchmarking on user engagement.
