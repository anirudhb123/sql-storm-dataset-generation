WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Start with Questions
    UNION ALL
    SELECT 
        p2.Id,
        p2.Title,
        p2.CreationDate,
        p2.ParentId,
        rh.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy rh ON p2.ParentId = rh.PostId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        rh.PostId,
        rh.Title,
        rh.CreationDate,
        COUNT(c.Id) AS TotalComments,
        AVG(vote.Score) AS AverageScore,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN usr.UserId IS NOT NULL THEN 1 ELSE 0 END) AS EngagedUserCount
    FROM
        RecursivePostHierarchy rh
    LEFT JOIN 
        Comments c ON rh.PostId = c.PostId
    LEFT JOIN 
        Votes vote ON rh.PostId = vote.PostId
    LEFT JOIN 
        PostHistory ph ON rh.PostId = ph.PostId
    LEFT JOIN 
        UserEngagement usr ON vote.UserId = usr.UserId
    GROUP BY 
        rh.PostId, rh.Title, rh.CreationDate
)
SELECT 
    ps.Title,
    ps.CreationDate,
    ps.TotalComments,
    ps.AverageScore,
    ps.CloseCount,
    COALESCE(ue.PostCount, 0) AS UserPostCount,
    (SELECT COUNT(DISTINCT UserId) FROM Votes v WHERE v.PostId = ps.PostId) AS UniqueVoterCount
FROM 
    PostStatistics ps
LEFT JOIN 
    UserEngagement ue ON ps.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = ue.UserId)
WHERE 
    ps.CloseCount > 0
ORDER BY 
    ps.AverageScore DESC, ps.TotalComments DESC;
