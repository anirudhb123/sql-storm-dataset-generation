WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.PostHistoryTypeId,
        1 AS Level
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Only Closed and Reopened
    
    UNION ALL

    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.PostHistoryTypeId,
        rp.Level + 1
    FROM 
        PostHistory ph
    JOIN 
        RecursivePostHistory rp ON ph.PostId = rp.PostId
    WHERE 
        (ph.PostHistoryTypeId = 10 AND rp.PostHistoryTypeId = 11)  -- Close followed by Reopen
        OR (ph.PostHistoryTypeId = 11 AND rp.PostHistoryTypeId = 10)  -- Reopen followed by Close
)
, UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.Reputation IS NULL THEN 0 ELSE u.Reputation END) AS TotalReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.Questions,
    ups.Answers,
    ups.TotalReputation,
    COUNT(DISTINCT rph.PostId) AS PostHistoryCount,
    MAX(rph.CreationDate) AS LastActivityDate
    
FROM 
    UserPostStats ups
LEFT JOIN 
    RecursivePostHistory rph ON ups.UserId = rph.UserId
WHERE 
    ups.PostCount > 0 
GROUP BY 
    ups.UserId, ups.DisplayName, ups.PostCount, ups.Questions, ups.Answers, ups.TotalReputation
HAVING 
    COUNT(DISTINCT rph.PostId) > 1 -- Users with more than one post history affected by close/reopen
ORDER BY 
    ups.TotalReputation DESC, ups.PostCount DESC;
