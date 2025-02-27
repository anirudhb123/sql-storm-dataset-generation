
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges,
        @row_number := @row_number + 1 AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId,
        (SELECT @row_number := 0) AS rn
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        @post_rank := @post_rank + 1 AS PostRank
    FROM 
        Posts p,
        (SELECT @post_rank := 0) AS pr
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
    ORDER BY 
        p.Score DESC, p.CreationDate DESC
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    ua.TotalBadges,
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CreationDate
FROM 
    UserActivity ua
JOIN 
    PostStatistics ps ON ua.TotalPosts > 5
WHERE 
    ua.UserRank <= 10 AND ps.PostRank <= 20
ORDER BY 
    ua.UserRank, ps.Score DESC;
