WITH RecursiveRank AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, Tags
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS TotalQuestions,
    COALESCE(SUM(t.TotalViews), 0) AS TotalTagViews,
    bh.BadgeCount,
    COALESCE(SUM(ph.EditCount), 0) AS TotalEdits,
    JSON_AGG(DISTINCT t.TagName) AS TagsUsed,
    RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS QuestionRank,
    "RANK"() OVER (PARTITION BY u.Id ORDER BY SUM(p.Score) DESC) AS ScoreRank
FROM 
    Users u
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1 -- Questions only
LEFT JOIN 
    TagStats t ON p.Tags LIKE '%' || t.TagName || '%' 
LEFT JOIN 
    UserBadges bh ON bh.UserId = u.Id
LEFT JOIN 
    PostHistoryStats ph ON ph.PostId = p.Id
WHERE 
    u.Reputation > 100 -- Filter users with reputation over 100
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, bh.BadgeCount
HAVING 
    COUNT(p.Id) > 10 -- Only consider users with more than 10 questions
ORDER BY 
    TotalQuestions DESC, TotalTagViews DESC;
