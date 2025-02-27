WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.AnswerCount,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.OwnerUserId IS NOT NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.AnswerCount,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    INNER JOIN RecursivePostStats r ON p.ParentId = r.PostId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT ps.PostId) AS TotalPosts,
    SUM(ps.AnswerCount) AS TotalAnswers,
    SUM(p.ViewCount) AS TotalViews,
    AVG(CASE WHEN ps.PostTypeId = 1 THEN ps.ViewCount ELSE NULL END) AS AvgQuestionViews,
    AVG(CASE WHEN ps.PostTypeId = 2 THEN ps.AnswerCount ELSE NULL END) AS AvgAnswerCount,
    MAX(ps.CreationDate) AS LastActivityDate,
    COUNT(b.Id) AS TotalBadges
FROM 
    Users u
LEFT JOIN 
    RecursivePostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    u.Reputation > 100 AND
    (u.Location IS NOT NULL OR u.WebsiteUrl IS NOT NULL)
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT ps.PostId) > 5
ORDER BY 
    TotalViews DESC, TotalPosts DESC;

WITH RecentClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.UserId,
        ph.CreationDate,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
        AND ph.CreationDate > NOW() - INTERVAL '30 days'
)

SELECT 
    rp.UserId,
    rp.Title,
    rp.CloseReason,
    CASE
        WHEN rp.CloseReason IN (SELECT Name FROM CloseReasonTypes) THEN 'Valid Close Reason'
        ELSE 'Unknown Reason'
    END AS CloseReasonValidity
FROM 
    RecentClosedPosts rp
WHERE 
    EXISTS (
        SELECT 1
        FROM Posts p
        WHERE p.Id = rp.PostId AND p.ParentId IS NULL
    );

SELECT 
    DISTINCT Tags.TagName,
    COUNT(t*post.Id) AS PostCount
FROM 
    Tags
LEFT JOIN 
    unnest(string_to_array(Tags, '><')) AS tag ON tag = Tags.TagName
JOIN 
    Posts p ON p.Tags LIKE '%' || tag || '%'
LEFT JOIN 
    PostLinks pl ON pl.PostId = p.Id
WHERE 
    Tags IS NOT NULL 
GROUP BY 
    Tags.TagName
HAVING 
    COUNT(p.Id) > 10;
