WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT 
        p2.Id,
        p2.ParentId,
        p2.Title,
        p2.CreationDate,
        rp.Level + 1
    FROM Posts p2
    INNER JOIN RecursivePostHierarchy rp ON p2.ParentId = rp.PostId
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT a.Id) AS AnswersProvided,
        SUM(V.CreationDate IS NOT NULL) AS VotesReceived
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
    LEFT JOIN Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2 -- Answers
    LEFT JOIN Votes V ON V.UserId = u.Id
    GROUP BY u.Id, u.DisplayName
),

TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS RelatedPosts,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%' -- Using like for tag association
    GROUP BY t.TagName
),

CloseReasonDetails AS (
    SELECT 
        ph.PostId, 
        ph.Comment AS CloseReason,
        ph.CreationDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.QuestionsAsked,
    u.AnswersProvided,
    u.VotesReceived,
    tp.TagName,
    ts.RelatedPosts,
    ts.TotalViews,
    ts.AverageScore,
    cp.CloseReason,
    cp.CreationDate AS CloseDate,
    rp.PostId AS ChildPostId,
    rp.Title AS ChildPostTitle,
    rp.Level
FROM UserActivity u
CROSS JOIN TagStats ts
LEFT JOIN CloseReasonDetails cp ON u.UserId = cp.PostId
LEFT JOIN RecursivePostHierarchy rp ON rp.PostId IN (SELECT DISTINCT AcceptedAnswerId FROM Posts p WHERE p.OwnerUserId = u.UserId)

WHERE 
    u.QuestionsAsked > 0
    AND ts.RelatedPosts > 5
    AND (cp.CloseReason IS NULL OR cp.CreationDate > NOW() - INTERVAL '1 year') -- Exclude close dates older than 1 year

ORDER BY 
    u.VotesReceived DESC,
    ts.TotalViews DESC;
