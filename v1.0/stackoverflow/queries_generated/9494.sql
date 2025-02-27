WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        AVG(vote.Score) AS AverageVoteScore,
        SUM(v.WoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(c.TotalComments, 0) AS TotalComments,
        COALESCE(ph.EditCount, 0) AS TotalEdits
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS TotalComments FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS EditCount FROM PostHistory GROUP BY PostId) ph ON p.Id = ph.PostId
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.Questions,
    ua.Answers,
    ua.Wikis,
    ua.AverageVoteScore,
    ps.Title,
    ps.ViewCount,
    ps.TotalComments,
    ps.TotalEdits
FROM 
    UserActivity ua
JOIN 
    PostStatistics ps ON ua.UserId = ps.OwnerUserId
ORDER BY 
    ua.TotalPosts DESC, ps.ViewCount DESC
LIMIT 100;
