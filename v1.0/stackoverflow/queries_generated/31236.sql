WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON ph.PostId = p.ParentId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        p.Title,
        ph.CreationDate,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS LastClosed,
        MAX(CASE WHEN pht.Name = 'Post Reopened' THEN ph.CreationDate END) AS LastReopened
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN 
        Posts p ON ph.PostId = p.Id
    GROUP BY 
        ph.Id, ph.PostId, p.Title, ph.CreationDate
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoters,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    upp.UserId,
    upp.DisplayName,
    upp.PostCount AS TotalPosts,
    upp.AnswerCount,
    upp.QuestionCount,
    upp.TotalScore,
    upp.AvgViews,
    COUNT(DISTINCT ph.PostId) AS LeafPosts,
    SUM(pm.CommentCount) AS TotalComments,
    SUM(pm.UniqueVoters) AS TotalUniqueVoters,
    SUM(pm.UpVotes) AS TotalUpVotes,
    SUM(pm.DownVotes) AS TotalDownVotes,
    MAX(rph.LastClosed) AS LastClosedDate,
    MAX(rph.LastReopened) AS LastReopenedDate
FROM 
    UserPostStats upp
LEFT JOIN 
    PostMetrics pm ON upp.UserId = p.OwnerUserId
LEFT JOIN 
    PostHierarchy ph ON pm.PostId = ph.PostId
LEFT JOIN 
    RecentPostHistory rph ON pm.PostId = rph.PostId
WHERE 
    upp.PostCount > 0
GROUP BY 
    upp.UserId, upp.DisplayName, upp.PostCount, upp.AnswerCount, 
    upp.QuestionCount, upp.TotalScore, upp.AvgViews;
