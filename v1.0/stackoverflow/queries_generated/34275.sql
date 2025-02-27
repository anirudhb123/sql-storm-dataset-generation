WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId,
        Title,
        ParentId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(DISTINCT b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(DISTINCT b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS ActivityRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate
),
PostStatistics AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.ViewCount,
        COALESCE(SUM(Votes.VoteTypeId = 2) - SUM(Votes.VoteTypeId = 3), 0) AS NetVotes,
        COUNT(DISTINCT Comments.Id) AS CommentCount,
        COUNT(DISTINCT Badges.Id) AS AwardCount,
        MAX(PostHistory.CreationDate) AS LastEditDate
    FROM 
        Posts
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Badges ON Posts.OwnerUserId = Badges.UserId
    LEFT JOIN 
        PostHistory ON Posts.Id = PostHistory.PostId
    GROUP BY 
        Posts.Id, Posts.Title, Posts.ViewCount
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.NetVotes,
    ps.CommentCount,
    ps.AwardCount,
    ps.LastEditDate,
    ups.TotalViews,
    ups.TotalBounty,
    ups.TotalPosts,
    ups.GoldBadges,
    ups.SilverBadges,
    ups.BronzeBadges,
    rph.Level AS PostLevel
FROM 
    PostStatistics ps
LEFT JOIN 
    UserSummary ups ON ps.OwnerUserId = ups.UserId
LEFT JOIN 
    RecursivePostHierarchy rph ON ps.PostId = rph.PostId
WHERE 
    (ps.ViewCount > 100 AND ups.TotalPosts > 1)
ORDER BY 
    ps.ViewCount DESC, 
    ps.NetVotes DESC;
