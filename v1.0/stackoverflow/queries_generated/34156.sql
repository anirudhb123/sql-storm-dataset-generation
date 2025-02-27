WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only want Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),

UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        AVG(VIEW_COUNT) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),

ClosedQuestionDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason,
        u.DisplayName AS ClosedBy
    FROM 
        PostHistory ph 
    INNER JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
    AND 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
),

PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    u.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.AvgViewCount,
    ph.PostId AS QuestionId,
    ph.Title AS QuestionTitle,
    cv.ClosedDate,
    cv.CloseReason,
    cv.ClosedBy,
    pvs.TotalVotes,
    pvs.UpVotes,
    pvs.DownVotes,
    RANK() OVER (PARTITION BY ph.PostId ORDER BY pvs.TotalVotes DESC) AS VoteRank
FROM 
    UserPostStats ups
INNER JOIN 
    RecursivePostHierarchy ph ON ups.UserId = ph.OwnerUserId
LEFT JOIN 
    ClosedQuestionDetails cv ON ph.PostId = cv.PostId
LEFT JOIN 
    PostVoteStats pvs ON ph.PostId = pvs.PostId
WHERE 
    ups.TotalPosts > 0
ORDER BY 
    ups.TotalPosts DESC, VoteRank;
