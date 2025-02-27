WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
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
        p.OwnerUserId,
        p.ParentId,
        r.Level + 1 AS Level
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.PostsCreated,
        ua.UpVotesReceived,
        ua.DownVotesReceived,
        RANK() OVER (ORDER BY ua.Reputation DESC) AS ReputationRank
    FROM 
        UserActivity ua
    WHERE 
        ua.PostsCreated > 0
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(ph.CloseReasonId, 0) AS CloseReasonId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            JSON_AGG(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReasonId
        FROM 
            PostHistory ph
        WHERE 
            ph.PostHistoryTypeId IN (10, 11)
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
),
FinalReport AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.Reputation,
        ps.PostId,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount,
        ps.CloseReasonId,
        ph.Level AS PostHierarchyLevel
    FROM 
        TopUsers u
    LEFT JOIN 
        PostStats ps ON u.UserId = ps.OwnerUserId
    LEFT JOIN 
        RecursivePostHierarchy ph ON ps.PostId = ph.PostId
)
SELECT 
    fr.UserId,
    fr.DisplayName,
    fr.Reputation,
    COUNT(DISTINCT fr.PostId) AS TotalPosts,
    SUM(fr.Score) AS TotalScore,
    SUM(fr.ViewCount) AS TotalViews,
    AVG(fr.CommentCount) AS AverageComments,
    ARRAY_AGG(DISTINCT fr.CloseReasonId) AS CloseReasons,
    MIN(fr.PostHierarchyLevel) AS MinHierarchyLevel,
    MAX(fr.PostHierarchyLevel) AS MaxHierarchyLevel
FROM 
    FinalReport fr
GROUP BY 
    fr.UserId,
    fr.DisplayName,
    fr.Reputation
ORDER BY 
    fr.Reputation DESC, 
    TotalPosts DESC;
