WITH UserReputation AS (
    SELECT 
        Id, 
        Reputation,
        CreationDate,
        CASE 
            WHEN Reputation < 100 THEN 'Newbie'
            WHEN Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM Users
),
RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    WHERE p.CreationDate > NOW() - INTERVAL '6 months'
),
CommonTags AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM Posts
    GROUP BY TagName
    HAVING COUNT(*) > 10
),
CloseReasonSummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY ph.PostId
),
RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
)

SELECT 
    u.DisplayName,
    ur.ReputationLevel,
    COUNT(DISTINCT rp.PostId) AS RecentPostCount,
    COALESCE(SUM(crs.CloseCount), 0) AS TotalCloseReasons,
    STRING_AGG(DISTINCT ct.TagName, ', ') AS FrequentTags
FROM 
    UserReputation ur
JOIN Users u ON ur.Id = u.Id
LEFT JOIN RecentPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN CloseReasonSummary crs ON crs.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
LEFT JOIN CommonTags ct ON ct.TagName IN (SELECT unnest(string_to_array(Tags, '><')) FROM Posts WHERE OwnerUserId = u.Id)
WHERE
    ur.CreationDate < COALESCE((SELECT MAX(CreationDate) FROM Users), NOW()) 
    AND (ur.ReputationLevel = 'Expert' OR ur.ReputationLevel = 'Intermediate')
GROUP BY 
    u.DisplayName, ur.ReputationLevel
ORDER BY 
    u.DisplayName
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
