WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS Downvotes,
        MAX(p.CreationDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.TotalComments,
        us.TotalUpvotes,
        us.TotalDownvotes,
        us.GoldBadges + us.SilverBadges + us.BronzeBadges AS TotalBadges,
        pa.CommentCount AS RecentCommentCount,
        pa.Upvotes AS RecentPostUpvotes,
        pa.Downvotes AS RecentPostDownvotes,
        pa.LastActivityDate
    FROM 
        UserStatistics us
    LEFT JOIN 
        PostActivity pa ON us.UserId = pa.OwnerUserId
    ORDER BY 
        us.TotalPosts DESC, us.TotalUpvotes DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalComments,
    tu.TotalUpvotes,
    tu.TotalDownvotes,
    tu.TotalBadges,
    tu.RecentCommentCount,
    tu.RecentPostUpvotes,
    tu.RecentPostDownvotes,
    tu.LastActivityDate
FROM 
    TopUsers tu;
