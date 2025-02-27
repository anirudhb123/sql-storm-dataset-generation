WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        1 AS Depth,
        CAST(p.Title AS VARCHAR(MAX)) AS FullTitle
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.OwnerUserId,
        ph.Depth + 1,
        CAST(ph.FullTitle + ' -> ' + a.Title AS VARCHAR(MAX)) 
    FROM 
        Posts a
    INNER JOIN 
        Posts q ON a.ParentId = q.Id
    INNER JOIN 
        RecursivePostHierarchy ph ON q.Id = ph.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(BadgeCount, 0) AS BadgeCount,
    COALESCE(AnswerCount, 0) AS AnswerCount,
    COALESCE(PostCount, 0) AS PostCount,
    COALESCE(DepthCount, 0) AS DepthCount
FROM 
    Users u
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        UserId
) AS UserBadges ON u.Id = UserBadges.UserId
LEFT JOIN (
    SELECT 
        OwnerUserId,
        COUNT(*) AS AnswerCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 2 -- Answers
    GROUP BY 
        OwnerUserId
) AS UserAnswers ON u.Id = UserAnswers.OwnerUserId
LEFT JOIN (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Questions
    GROUP BY 
        OwnerUserId
) AS UserPosts ON u.Id = UserPosts.OwnerUserId
LEFT JOIN (
    SELECT 
        OwnerUserId,
        SUM(Depth) AS DepthCount
    FROM 
        RecursivePostHierarchy
    GROUP BY 
        OwnerUserId
) AS PostDepth ON u.Id = PostDepth.OwnerUserId
WHERE 
    u.Reputation > 100 -- Filter for users with high reputation
ORDER BY 
    u.Reputation DESC,
    BadgeCount DESC,
    AnswerCount DESC;
