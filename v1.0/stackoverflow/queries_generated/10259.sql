-- Performance Benchmarking Query
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounties,
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
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        pt.Name AS PostType,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, pt.Name
),
BenchmarkResults AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalComments,
        ua.TotalBounties,
        ua.GoldBadges,
        ua.SilverBadges,
        ua.BronzeBadges,
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.PostType,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes
    FROM 
        UserActivity ua
    JOIN 
        PostDetails pd ON ua.UserId = pd.PostId  -- Ensuring we link user activity with post details
)
SELECT *
FROM BenchmarkResults
ORDER BY TotalPosts DESC, TotalComments DESC, TotalBounties DESC;
