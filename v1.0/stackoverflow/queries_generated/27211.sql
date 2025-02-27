WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
RecentUserActivities AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT ph.PostId) AS TotalPostHistory,
        AVG(DATEDIFF(MINUTE, ph.CreationDate, GETDATE())) AS AvgTimeSinceLastEdit
    FROM 
        Users u
    JOIN 
        PostHistory ph ON u.Id = ph.UserId
    WHERE 
        ph.CreationDate > DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')))
    GROUP BY 
        p.Id
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.PostId) AS TotalQuestions,
    SUM(p.ViewCount) AS TotalViews,
    SUM(p.Score) AS TotalScore,
    STRING_AGG(pt.TagsList, '; ') AS AllTagsUsed,
    ra.rank AS TopRankedPost
FROM 
    RecentUserActivities u
JOIN 
    RankedPosts p ON u.UserId = p.OwnerUserId
LEFT JOIN 
    PostTags pt ON p.PostId = pt.PostId
GROUP BY 
    u.UserId, u.DisplayName, u.Reputation, ra.rank
HAVING 
    COUNT(DISTINCT p.PostId) > 10 -- Users with more than 10 questions
ORDER BY 
    TotalScore DESC, TotalViews DESC;
