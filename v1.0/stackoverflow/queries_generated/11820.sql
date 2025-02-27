-- Performance benchmarking query for Stack Overflow database schema

WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        Views,
        UpVotes,
        DownVotes,
        (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = Users.Id) AS PostCount,
        (SELECT COUNT(*) FROM Badges WHERE UserId = Users.Id) AS BadgeCount
    FROM 
        Users
),
PostStatistics AS (
    SELECT
        PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore,
        AVG(CASE WHEN AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptanceRate
    FROM 
        Posts
    WHERE 
        CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        PostTypeId
),
CommentsOverview AS (
    SELECT
        PostId,
        COUNT(*) AS TotalComments,
        AVG(Score) AS AverageCommentScore
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    u.UserId,
    u.Reputation,
    u.CreationDate,
    u.LastAccessDate,
    u.Views,
    u.UpVotes,
    u.DownVotes,
    u.PostCount,
    u.BadgeCount,
    p.PostTypeId,
    p.TotalPosts,
    p.TotalViews,
    p.AverageScore,
    p.AcceptanceRate,
    c.TotalComments,
    c.AverageCommentScore
FROM 
    UserReputation u
JOIN 
    PostStatistics p ON p.PostTypeId IN (1, 2) -- Filter for specific post types (Questions and Answers)
LEFT JOIN 
    CommentsOverview c ON c.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.UserId)
ORDER BY 
    u.Reputation DESC, p.TotalViews DESC;
