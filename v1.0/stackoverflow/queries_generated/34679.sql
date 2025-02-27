WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Starting with top-level posts (questions only)
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT a.Id) AS AnswersProvided,
        SUM(v.BountyAmount) AS TotalBountyReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  -- Questions
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2  -- Answers
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9)  -- BountyStart & BountyClose
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEdited,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TagStats AS (
    SELECT 
        t.Id,
        t.TagName,
        COUNT(tp.PostId) AS AssociatedPostCount,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        PostLinks tp ON p.Id = tp.PostId
    GROUP BY 
        t.Id
)
SELECT 
    u.DisplayName,
    e.QuestionsAsked,
    e.AnswersProvided,
    ts.TagName,
    ts.AssociatedPostCount,
    ts.AvgViewCount,
    phs.LastEdited,
    phs.CloseReopenCount,
    COUNT(DISTINCT r.PostId) AS RelatedPostsCount
FROM 
    UserEngagement e
JOIN 
    Users u ON e.UserId = u.Id
LEFT JOIN 
    PostHistorySummary phs ON phs.PostId IN (
        SELECT 
            PostId 
        FROM 
            Posts 
        WHERE 
            OwnerUserId = u.Id
    )
LEFT JOIN 
    TagStats ts ON ts.TagName IN (
        SELECT 
            DISTINCT unnest(string_to_array(p.Tags, '><')) 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = u.Id
    )
LEFT JOIN 
    RecursivePostHierarchy r ON r.OwnerUserId = u.Id
WHERE 
    e.QuestionsAsked > 0
GROUP BY 
    u.DisplayName, e.QuestionsAsked, e.AnswersProvided, ts.TagName, ts.AssociatedPostCount, ts.AvgViewCount, phs.LastEdited, phs.CloseReopenCount
ORDER BY 
    e.QuestionsAsked DESC, e.AnswersProvided DESC, ts.AssociatedPostCount DESC;
