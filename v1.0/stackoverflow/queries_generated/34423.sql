WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
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
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseReasonCount,
        STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasons
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    JOIN 
        CloseReasonTypes c ON c.Id = CAST(ph.Comment AS int) 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        p.Id, p.Title, ph.CreationDate
),
PostDetails AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COALESCE(upv.UpVotes, 0) - COALESCE(dnv.DownVotes, 0) AS NetVotes,
        CASE 
            WHEN c.CloseReasonCount > 0 THEN 'Closed'
            ELSE 'Active'
        END AS Status
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteSummary upv ON p.Id = upv.PostId
    LEFT JOIN 
        PostVoteSummary dnv ON p.Id = dnv.PostId 
    LEFT JOIN 
        ClosedPosts c ON p.Id = c.Id
)
SELECT 
    pd.Id AS PostId,
    pd.Title,
    pd.CreationDate,
    pd.NetVotes,
    pd.Status,
    ur.Reputation AS UserReputation,
    ur.BadgeCount,
    STRING_AGG(DISTINCT ph.Title, ' -> ') AS ParentPosts
FROM 
    PostDetails pd
INNER JOIN 
    Users u ON pd.OwnerUserId = u.Id
INNER JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    RecursivePostHierarchy ph ON pd.Id = ph.PostId
GROUP BY 
    pd.Id, pd.Title, pd.CreationDate, pd.NetVotes, pd.Status, ur.Reputation, ur.BadgeCount
ORDER BY 
    pd.CreationDate DESC;
