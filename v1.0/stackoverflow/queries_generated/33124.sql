WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting from Questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation AS UserReputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(*) AS TotalEdits,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS TotalCloseEvents
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    p.Id AS PostId,
    p.Title,
    COALESCE(r.Level, 0) AS AnswerLevel,
    u.DisplayName AS OwnerName,
    UP.UserReputation,
    phs.LastEditDate,
    phs.TotalEdits,
    phs.TotalCloseEvents,
    pvs.UpVotes,
    pvs.DownVotes,
    CASE 
        WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AnswerStatus
FROM 
    Posts p
LEFT JOIN 
    RecursivePostHierarchy r ON p.Id = r.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation UP ON u.Id = UP.UserId
LEFT JOIN 
    PostVoteSummary pvs ON p.Id = pvs.PostId
LEFT JOIN 
    PostHistorySummary phs ON p.Id = phs.PostId
WHERE 
    p.PostTypeId = 2  -- We are only interested in Answers
ORDER BY 
    p.Score DESC,  -- For added analysis of performance, ordering by Score
    u.Reputation DESC;  -- And by User Reputation to get a sense of quality
