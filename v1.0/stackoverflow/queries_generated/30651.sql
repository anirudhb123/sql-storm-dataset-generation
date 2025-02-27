WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    JOIN 
        Posts a ON p.ParentId = a.Id
    WHERE 
        a.PostTypeId = 1  -- Ensure to take only questions as parent
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        (u.UpVotes - u.DownVotes) AS NetVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryDetail AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.Comment,
        ph.CreationDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Closed and Reopened
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.UserId) AS CloseVoteCount,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS CloseReasons
    FROM 
        PostHistoryDetail ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title AS QuestionTitle, 
    p.CreationDate AS QuestionDate,
    COALESCE(u.DisplayName, 'Deleted User') AS OwnerName,
    COALESCE(ps.CloseVoteCount, 0) AS CloseVoteCount,
    COALESCE(ps.CloseReasons, 'No reasons provided') AS CloseReasons,
    us.Reputation,
    us.TotalPosts,
    us.TotalAnswers,
    us.TotalBadges,
    ROW_NUMBER() OVER (ORDER BY us.Reputation DESC) AS UserRank
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    ClosedPosts ps ON p.Id = ps.PostId
LEFT JOIN 
    UserScores us ON u.Id = us.UserId
WHERE 
    ps.CloseVoteCount > 0 OR ps.CloseVoteCount IS NULL
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
