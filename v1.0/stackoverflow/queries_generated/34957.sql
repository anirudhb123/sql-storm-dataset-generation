WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Selecting only Questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.CreationDate,
        a.PostTypeId,
        a.ParentId,
        h.Level + 1 AS Level
    FROM 
        Posts AS a
    JOIN 
        PostHierarchy h ON a.ParentId = h.PostId
    WHERE 
        a.PostTypeId = 2 -- Selecting only Answers
)

SELECT 
    u.DisplayName,
    u.Reputation,
    p.Title AS QuestionTitle,
    COUNT(c.Id) AS CommentCount,
    AVG(v.BountyAmount) AS AverageBounty,
    MAX(CASE WHEN bh.Class = 1 THEN 1 ELSE 0 END) AS GoldBadge,
    MAX(CASE WHEN bh.Class = 2 THEN 1 ELSE 0 END) AS SilverBadge,
    MAX(CASE WHEN bh.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadge,
    bh.Date AS BadgeDate,
    p.CreatedAt
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- considering Bounties 
LEFT JOIN 
    Badges bh ON u.Id = bh.UserId
LEFT JOIN 
    (SELECT DISTINCT PostId FROM PostHistory PH WHERE PH.PostHistoryTypeId IN (10, 11)) PHFiltered ON p.Id = PHFiltered.PostId -- Posts that have been closed or reopened
WHERE 
    p.CreationDate BETWEEN '2022-01-01' AND '2023-10-01'
GROUP BY 
    u.DisplayName, u.Reputation, p.Title, bh.Date
HAVING 
    COUNT(c.Id) > 5 -- Users who have made significant contributions to posts with comments
ORDER BY 
    u.Reputation DESC, COUNT(c.Id) DESC;

WITH AverageViews AS (
    SELECT 
        p.OwnerUserId,
        AVG(p.Views) AS AvgViewCount
    FROM 
        Posts p 
    GROUP BY 
        p.OwnerUserId
)

SELECT 
    u.DisplayName,
    AVG(av.AvgViewCount) AS UserAvgViewCount,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
FROM 
    Users u
LEFT JOIN 
    AverageViews av ON av.OwnerUserId = u.Id
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id
WHERE 
    u.Reputation > 100 -- Getting users with significant reputation
GROUP BY 
    u.DisplayName
ORDER BY 
    UserAvgViewCount DESC
FETCH FIRST 10 ROWS ONLY;
