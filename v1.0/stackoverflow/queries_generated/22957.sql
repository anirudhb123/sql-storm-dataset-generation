WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank,
        COUNT(b.Id) AS BadgeCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > DATEADD(DAY, -30, GETDATE())
),
UserPostStatistics AS (
    SELECT 
        ru.UserId,
        ru.DisplayName,
        COUNT(rp.PostId) AS TotalRecentPosts,
        SUM(rp.Score) AS TotalScore,
        CONCAT(COALESCE(MAX(rp.CreationDate), 'No Posts'), ' - ', COALESCE(MIN(rp.CreationDate), 'No Posts')) AS PostDateRange
    FROM 
        RankedUsers ru
    LEFT JOIN 
        RecentPosts rp ON ru.UserId = rp.OwnerUserId
    GROUP BY 
        ru.UserId, ru.DisplayName
)
SELECT 
    ups.DisplayName,
    ups.TotalRecentPosts,
    ups.TotalScore, 
    ups.PostDateRange,
    RANK() OVER (ORDER BY ups.TotalScore DESC) AS ScoreRank,
    CASE 
        WHEN ups.TotalRecentPosts > 5 THEN 'Frequent Author'
        WHEN ups.TotalRecentPosts BETWEEN 1 AND 5 THEN 'Occasional Author'
        ELSE 'No Recent Activity'
    END AS EngagementLevel
FROM 
    UserPostStatistics ups
WHERE 
    ups.TotalScore IS NOT NULL AND 
    ups.TotalRecentPosts > 0
ORDER BY 
    ScoreRank;

-- Add further analytics on posts that have a specific tag and have been edited more than twice.
WITH FrequentEdits AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS EditCount,
        p.Title,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    JOIN 
        STRING_TO_ARRAY(p.Tags, ',') AS TagNames(tag) ON t.Id = CAST(tag AS INT)
    GROUP BY 
        p.Id, p.Title
    HAVING 
        COUNT(ph.Id) > 2
)
SELECT 
    fe.Title,
    fe.EditCount,
    fe.Tags,
    CASE 
        WHEN fe.EditCount = 3 THEN 'Edited Three Times'
        ELSE 'Highly Edited'
    END AS EditLevel
FROM 
    FrequentEdits fe
ORDER BY 
    fe.EditCount DESC;

-- Explore how many posts a user has closed based on close reason types.
SELECT 
    u.DisplayName,
    COUNT(ph.Id) AS ClosedPostCount,
    STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons
FROM 
    Users u
JOIN 
    PostHistory ph ON ph.UserId = u.Id AND ph.PostHistoryTypeId = 10
JOIN 
    CloseReasonTypes ctr ON ph.Comment::json->>'CloseReasonId'::INT = ctr.Id
GROUP BY 
    u.Id
HAVING 
    COUNT(ph.Id) > 0
ORDER BY 
    ClosedPostCount DESC;
