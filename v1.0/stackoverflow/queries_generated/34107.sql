WITH RecursiveTagPostCount AS (
    SELECT 
        t.Id AS TagId, 
        t.TagName, 
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%<' || t.TagName || '>%' -- using LIKE to find posts with the tag
    GROUP BY t.Id, t.TagName

    UNION ALL

    SELECT 
        t.Id,
        t.TagName,
        COUNT(DISTINCT p.Id) + r.PostCount
    FROM Tags t
    JOIN RecursiveTagPostCount r ON t.Id = r.TagId 
    LEFT JOIN Posts p ON p.Tags LIKE '%<' || t.TagName || '>%'
    WHERE r.PostCount > 0
)

, UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
)

, PopularPostSummary AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        ub.UserId AS BestAnswererId,
        ub.Reputation
    FROM Posts p
    LEFT JOIN (
        SELECT 
            p.AcceptedAnswerId AS BestAnswerId,
            p.OwnerUserId AS UserId,
            u.Reputation
        FROM Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
        WHERE p.AcceptedAnswerId IS NOT NULL
    ) ub ON p.Id = ub.BestAnswerId
    WHERE p.PostTypeId = 1 -- only questions
)

SELECT 
    t.TagName,
    r.PostCount,
    ups.UserId,
    ups.DisplayName,
    ups.Reputation,
    ups.ReputationRank,
    p.PostId,
    p.Title,
    p.Score,
    p.ViewCount
FROM RecursiveTagPostCount r
JOIN Tags t ON r.TagId = t.Id
LEFT JOIN UserReputation ups ON ups.Reputation > 1000 -- users with reputation above 1000
JOIN PopularPostSummary p ON p.BestAnswererId = ups.UserId
WHERE 
    r.PostCount > 5 AND -- filtering tags with more than 5 posts
    p.Score > 10 -- only popular questions
ORDER BY r.PostCount DESC, p.ViewCount DESC;
