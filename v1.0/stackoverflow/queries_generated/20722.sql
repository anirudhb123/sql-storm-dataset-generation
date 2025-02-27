WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS UserRank,
        (SELECT COUNT(*) FROM Posts p2 WHERE p2.AcceptedAnswerId = p.Id) AS NumAcceptedAnswers,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Has Accepted Answer' 
            ELSE 'No Accepted Answer' 
        END AS AcceptanceStatus
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score > 0
    GROUP BY 
        p.Id
),
UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS MaxBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        ubs.UserId,
        ubs.DisplayName,
        p.ViewCount + COALESCE(ubs.BadgeCount * 50, 0) AS EngagementScore
    FROM 
        UserBadgeStats ubs
    JOIN PostStats ps ON ps.UserRank <= 5 AND ps.UpVotes > 10
),
MostPopularPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        ps.AcceptanceStatus
    FROM 
        PostStats ps
    ORDER BY 
        ps.ViewCount DESC
    LIMIT 10
)

SELECT 
    mpp.Title AS PopularPostTitle,
    u.DisplayName AS TopUserName,
    mpp.ViewCount AS PostViewCount,
    u.BadgeCount AS UserBadgeCount,
    u.MaxBadgeClass AS UserMaxBadgeClass,
    mpp.AcceptanceStatus
FROM 
    MostPopularPosts mpp
JOIN 
    TopUsers u ON mpp.PostId IN (
        SELECT PostId FROM Posts WHERE OwnerUserId = u.UserId
    )
ORDER BY 
    mpp.ViewCount DESC, u.EngagementScore DESC 
LIMIT 5
OFFSET 0;

-- Additionally, retrieve null logic and edge cases
SELECT 
    p.Id AS PostId,
    CASE 
        WHEN p.ClosedDate IS NULL THEN 'Open' 
        ELSE 'Closed' 
    END AS Status,
    COALESCE(c.Text, 'No Comments') AS CommentPreview
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.ViewCount IS NOT NULL 
    AND (c.UserId IS NULL OR c.UserId NOT IN (SELECT DISTINCT UserId FROM Users WHERE Reputation < 100))
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
