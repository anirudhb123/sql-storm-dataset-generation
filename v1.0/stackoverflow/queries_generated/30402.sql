WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        PostTypeId,
        AcceptedAnswerId,
        ParentId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Start with Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
),
PostVoteSummary AS (
    SELECT 
        p.Id,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate AS CloseDate,
        ph.UserId AS ClosedBy,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
)
SELECT 
    u.DisplayName,
    u.Reputation,
    rph.Title AS QuestionTitle,
    COUNT(DISTINCT rph.Id) AS AnswerCount,
    COALESCE(SUM(pvs.Upvotes), 0) AS TotalUpvotes,
    COALESCE(SUM(pvs.Downvotes), 0) AS TotalDownvotes,
    cp.CloseDate AS PostClosedDate,
    cp.CloseReason AS ReasonForClosure
FROM 
    UserReputation u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    RecursivePostHierarchy rph ON p.AcceptedAnswerId = rph.Id
LEFT JOIN 
    PostVoteSummary pvs ON p.Id = pvs.Id
LEFT JOIN 
    ClosedPosts cp ON p.Id = cp.Id
WHERE 
    u.Reputation > 100 
GROUP BY 
    u.Id, 
    u.DisplayName, 
    u.Reputation, 
    rph.Title, 
    cp.CloseDate, 
    cp.CloseReason
ORDER BY 
    u.Reputation DESC,
    rph.Title
LIMIT 100;

