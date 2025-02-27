WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS RankByComments,
        DENSE_RANK() OVER(ORDER BY SUM(v.CreationDate IS NOT NULL) DESC) AS PopularityRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(ps.UpVoteCount), 0) AS TotalUpVotes,
        COALESCE(SUM(ps.DownVoteCount), 0) AS TotalDownVotes,
        COUNT(DISTINCT ps.PostId) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN b.Name IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        PostStatistics ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ua.*,
        RANK() OVER(ORDER BY TotalUpVotes - TotalDownVotes DESC) AS UserRank
    FROM 
        UserActivity ua
    WHERE 
        TotalPosts > 0
)
SELECT 
    tu.DisplayName,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    tu.TotalPosts,
    tu.TotalComments,
    tu.UserRank,
    CASE 
        WHEN tu.UserRank = 1 THEN 'Top Contributor'
        WHEN tu.TotalBadges > 5 THEN 'Active Contributor'
        ELSE 'New Contributor'
    END AS UserType
FROM 
    TopUsers tu
WHERE 
    tu.UserRank <= 10 OR (tu.TotalComments > 50 AND tu.UserRank <= 25)
ORDER BY 
    tu.UserRank;

-- Additional complex criteria including string manipulation to concatenate badges
SELECT 
    u.DisplayName,
    STRING_AGG(DISTINCT b.Name, ', ') AS BadgeList,
    COALESCE(b.TotalBadges, 0) AS BadgeCount
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT b.Id) > 0
ORDER BY 
    BadgeCount DESC;

This query performs several advanced SQL techniques, including Common Table Expressions (CTEs), aggregation, window functions, and string concatenation. It provides insights into user activity and ranks users based on their contributions, while simultaneously offering detailed statistics about the posts, comments, and votes associated with each user. The additional query lists users with their associated badges, demonstrating effective use of grouping and filtering mechanics.
