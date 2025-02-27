WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(pc.ClosedDate, '1970-01-01') AS ClosedDate,
        pt.Name AS PostType
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        (SELECT PostId, MAX(ClosedDate) AS ClosedDate FROM Posts WHERE ClosedDate IS NOT NULL GROUP BY PostId) pc ON p.Id = pc.PostId
),
UserPostStats AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        COUNT(ps.PostId) AS PostParticipation,
        AVG(ps.Score) AS AvgPostScore,
        AVG(ps.ViewCount) AS AvgViewCount,
        COUNT(CASE WHEN ps.ClosedDate <> '1970-01-01' THEN 1 END) AS ClosedPosts
    FROM 
        UserActivity ua
    LEFT JOIN 
        PostStats ps ON ua.UserId = ps.PostId
    GROUP BY 
        ua.UserId, ua.DisplayName
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.TotalPosts,
    u.TotalComments,
    u.TotalUpVotes,
    u.TotalDownVotes,
    ups.PostParticipation,
    ups.AvgPostScore,
    ups.AvgViewCount,
    ups.ClosedPosts
FROM 
    UserActivity u
JOIN 
    UserPostStats ups ON u.UserId = ups.UserId
ORDER BY 
    u.TotalPosts DESC, u.Reputation DESC
LIMIT 100;
