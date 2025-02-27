WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        OwnerUserId,
        CreationDate,
        1 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.OwnerUserId,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        p.Title,
        ph.CreationDate,
        pt.Name AS PostHistoryType
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    INNER JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
),
AggregateVoteStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.UserId END) AS UniqueUpVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.UserId END) AS UniqueDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    r.Id AS PostId,
    r.Title,
    r.Level,
    u.DisplayName AS Owner,
    COALESCE(ue.UpVotes, 0) AS UserUpVotes,
    COALESCE(ue.DownVotes, 0) AS UserDownVotes,
    ua.CommentCount AS UserCommentCount,
    ph.PostHistoryType,
    ph.CreationDate AS HistoryDate,
    av.UniqueUpVotes,
    av.UniqueDownVotes
FROM 
    RecursivePostHierarchy r
LEFT JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    UserEngagement ue ON u.Id = ue.UserId
LEFT JOIN 
    RecentPostHistory ph ON r.Id = ph.PostId
LEFT JOIN 
    AggregateVoteStatistics av ON r.Id = av.PostId
WHERE 
    r.Level <= 3
ORDER BY 
    r.CreationDate DESC, r.Level ASC;
