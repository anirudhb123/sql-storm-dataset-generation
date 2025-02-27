WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount
    FROM 
        RankedUsers
    WHERE 
        UserRank <= 10
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Gold badges only
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ps.TotalPosts,
    ps.PositivePosts,
    ps.NegativePosts,
    ps.AvgViewCount,
    COALESCE(ub.BadgeNames, 'None') AS GoldBadges
FROM 
    TopUsers u
LEFT JOIN 
    PostStats ps ON u.UserId = ps.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.UserId = ub.UserId
ORDER BY 
    u.Reputation DESC;

WITH RECURSIVE TagHierarchy AS (
    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        1 AS Level
    FROM 
        Tags t
    WHERE 
        t.IsModeratorOnly = 0

    UNION ALL

    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        th.Level + 1
    FROM 
        Tags t
    JOIN 
        TagHierarchy th ON t.WikiPostId = th.Id
)
SELECT 
    Id,
    TagName,
    Level,
    Count
FROM 
    TagHierarchy
WHERE 
    Level < 5
ORDER BY 
    Level, Count DESC;

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    ph.Comment AS PostEditComment,
    ph.CreationDate AS EditDate,
    ph.UserDisplayName AS EditorName
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5) -- Edit Title, Edit Body
WHERE 
    p.CreationDate > NOW() - INTERVAL '1 year' -- Posts created in the last year
ORDER BY 
    p.CreationDate DESC;
