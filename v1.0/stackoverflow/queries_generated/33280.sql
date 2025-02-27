WITH RecursiveTagCount AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(t.TagName) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadgeClass,
        MAX(p.CreationDate) AS LastActivePostDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        MAX(ph.CreationDate) AS LastClosedDate,
        COUNT(ph.Id) AS CloseReasonCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id, p.Title
),
TaggedUserPostStats AS (
    SELECT 
        utc.Id AS UserId,
        utc.DisplayName,
        rtc.TagCount,
        COALESCE(cp.LastClosedDate, 'Never Closed') AS LastClosed,
        COALESCE(cp.CloseReasonCount, 0) AS ClosedCount
    FROM 
        UserReputation utc
    LEFT JOIN 
        RecursiveTagCount rtc ON utc.Id = rtc.OwnerUserId
    LEFT JOIN 
        ClosedPosts cp ON rtc.PostId = cp.PostId
)
SELECT 
    tuv.UserId,
    tuv.DisplayName,
    tuv.Reputation,
    tuv.TagCount,
    tuv.LastClosed,
    tuv.ClosedCount,
    COALESCE(tu.TotalBadgeClass, 0) AS TotalBadges,
    CASE 
        WHEN tuv.TagCount > 5 THEN 'Expert'
        WHEN tuv.TagCount BETWEEN 3 AND 5 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel
FROM 
    TaggedUserPostStats tuv
LEFT JOIN 
    UserReputation tu ON tuv.UserId = tu.Id
ORDER BY 
    tuv.Reputation DESC, 
    tuv.TagCount DESC;
