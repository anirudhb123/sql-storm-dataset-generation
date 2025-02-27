WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        AVG(p.Score) AS AveragePostScore,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount
),

MostActiveUsers AS (
    SELECT 
        u.DisplayName,
        ua.TotalPosts,
        ua.TotalComments,
        ua.TotalUpVotes,
        ua.TotalDownVotes,
        ua.AveragePostScore,
        ua.TotalBadges,
        RANK() OVER (ORDER BY ua.TotalPosts DESC) AS UserRank
    FROM 
        UserActivity ua
    ORDER BY 
        ua.TotalPosts DESC
),

TopPosts AS (
    SELECT 
        ps.Title,
        ps.CreationDate,
        ps.ViewCount,
        ps.Score,
        ps.AnswerCount,
        RANK() OVER (ORDER BY ps.Score DESC) AS PostRank
    FROM 
        PostStatistics ps
    ORDER BY 
        ps.Score DESC
)

SELECT 
    mu.DisplayName AS MostActiveUser,
    mu.TotalPosts,
    mu.TotalComments,
    mu.TotalUpVotes,
    mu.TotalDownVotes,
    mu.AveragePostScore,
    mu.TotalBadges,
    tp.Title AS TopPostTitle,
    tp.CreationDate AS TopPostCreationDate,
    tp.ViewCount AS TopPostViewCount,
    tp.Score AS TopPostScore,
    tp.AnswerCount AS TopPostAnswerCount
FROM 
    MostActiveUsers mu
CROSS JOIN 
    TopPosts tp
WHERE 
    mu.UserRank = 1 AND tp.PostRank = 1;
