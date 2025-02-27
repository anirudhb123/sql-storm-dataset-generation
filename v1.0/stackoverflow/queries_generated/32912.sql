WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.OwnerUserId, 
        p.CreationDate,
        0 AS Level,
        CAST(p.Title AS varchar(300)) AS Path
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with questions
    UNION ALL
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.OwnerUserId, 
        p.CreationDate,
        rph.Level + 1,
        CAST(rph.Path + ' -> ' + p.Title AS varchar(300)) AS Path
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
    WHERE 
        p.PostTypeId = 2  -- Answers
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpvoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownvoteCount,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
ClosedPostSummary AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        COUNT(*) AS TotalCloseActions,
        STRING_AGG(DISTINCT cht.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cht ON ph.Comment::int = cht.Id 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Closed and Reopened actions
    GROUP BY 
        ph.PostId, ph.UserId, ph.CreationDate
)
SELECT 
    u.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.UpvoteCount,
    ups.DownvoteCount,
    ups.PostRank,
    COALESCE(cps.TotalCloseActions, 0) AS CloseActionCount,
    COALESCE(cps.CloseReasons, 'None') AS CloseReasons,
    rph.Path AS PostHierarchyPath
FROM 
    UserPostStats ups
LEFT JOIN 
    ClosedPostSummary cps ON ups.UserId = cps.UserId
LEFT JOIN 
    RecursivePostHierarchy rph ON rph.OwnerUserId = ups.UserId
WHERE 
    ups.TotalPosts > 0
ORDER BY 
    ups.PostRank ASC, 
    ups.DisplayName;
