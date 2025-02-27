WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.OwnerUserId,
        ph.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        PostHierarchy ph ON a.ParentId = ph.PostId
    WHERE 
        a.PostTypeId = 2  -- Joining Answers to Questions
),
PostDetails AS (
    SELECT 
        ph.PostId,
        ph.Title,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(UP.VoteCount, 0) AS UpVoteCount,
        COALESCE(DN.VoteCount, 0) AS DownVoteCount,
        ph.Level,
        COUNT(DISTINCT c.Id) AS CommentCount,
        MAX(COALESCE(p.AcceptedAnswerId, 0)) AS AcceptedAnswerId
    FROM 
        PostHierarchy ph
    LEFT JOIN 
        Users u ON ph.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = ph.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS VoteCount FROM Votes WHERE VoteTypeId = 2 GROUP BY PostId) AS UP ON UP.PostId = ph.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS VoteCount FROM Votes WHERE VoteTypeId = 3 GROUP BY PostId) AS DN ON DN.PostId = ph.PostId
    LEFT JOIN 
        Comments c ON c.PostId = ph.PostId
    GROUP BY 
        ph.PostId, ph.Title, u.DisplayName, UP.VoteCount, DN.VoteCount, ph.Level
),
RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.LastActivityDate IS NOT NULL
),
AggregatedData AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.OwnerDisplayName,
        pd.UpVoteCount,
        pd.DownVoteCount,
        pd.Level,
        pd.CommentCount,
        rp.LastActivityDate
    FROM 
        PostDetails pd
    LEFT JOIN 
        RecentPostActivity rp ON pd.PostId = rp.PostId AND rp.rn = 1
)

SELECT 
    ag.PostId,
    ag.Title,
    ag.OwnerDisplayName,
    ag.UpVoteCount,
    ag.DownVoteCount,
    ag.Level,
    ag.CommentCount,
    CASE 
        WHEN ag.LastActivityDate < NOW() - INTERVAL '30 days' THEN 'Inactive'
        ELSE 'Active' 
    END AS ActivityStatus
FROM 
    AggregatedData ag
WHERE 
    ag.UpVoteCount > ag.DownVoteCount
ORDER BY 
    ag.UpVoteCount DESC, 
    ag.CommentCount DESC;
