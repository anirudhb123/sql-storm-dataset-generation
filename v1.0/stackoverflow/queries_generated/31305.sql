WITH RecursivePostHierarchy AS (
    -- CTE to recursively find all answers for each question
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions only

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        Posts a ON p.Id = a.ParentId  -- Join on answers
    WHERE 
        a.PostTypeId = 2  -- Answers only
)

, UserReputation AS (
    -- CTE to calculate the total reputation score for each user based on their posts and answers
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT a.Id) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
    GROUP BY 
        u.Id
)

-- Main query to get user details along with their reputation and post/answer count
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    ur.TotalScore,
    ur.PostCount,
    ur.AnswerCount,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.UserId = u.Id) AS CommentCount,
    STRING_AGG(t.TagName, ', ') AS TagsUsed
FROM 
    Users u
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    LATERAL (
        SELECT 
            DISTINCT unnest(string_to_array(p.Tags, ',')) AS TagName
    ) t ON true  -- Unnest the tags into a set for aggregation
WHERE 
    u.Reputation > 1000  -- Only considering users with a reputation > 1000
GROUP BY 
    u.Id, ur.TotalScore, ur.PostCount, ur.AnswerCount
ORDER BY 
    ur.TotalScore DESC, 
    u.Reputation DESC
LIMIT 100;

-- This complex query benchmark results by processing user reputations, posts, tag usage, 
-- comments, and badge counts, demonstrating various SQL features such as recursive CTEs, 
-- lateral joins, aggregation, and conditional metrics.
