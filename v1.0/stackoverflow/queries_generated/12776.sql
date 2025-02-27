-- Performance benchmarking query to assess user activity and post engagement

WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,
        SUM(v.VoteTypeId = 1) AS TotalAccepted
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBadges,
    ua.TotalBounty,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    ua.TotalAccepted
FROM
    UserActivity ua
ORDER BY
    ua.TotalPosts DESC,
    ua.TotalComments DESC;

