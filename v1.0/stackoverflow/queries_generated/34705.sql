WITH RECURSIVE UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostWithVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS CloseDate,
        ph.UserId AS ClosedByUserId,
        ph.Comment
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
        AND p.PostTypeId = 1
),
UserStats AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        ub.TotalBadges,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) AS TotalPosts,
        (SELECT COUNT(*) FROM ClosedPosts cp WHERE cp.ClosedByUserId = u.Id) AS ClosedPostsCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)

SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalBadges,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    COUNT(DISTINCT cp.PostId) AS TotalClosedPosts,
    AVG(pwv.Score) AS AvgScore,
    SUM(pwv.UpVotes) AS TotalUpVotes,
    SUM(pwv.DownVotes) AS TotalDownVotes
FROM 
    UserStats us
LEFT JOIN 
    ClosedPosts cp ON us.Id = cp.ClosedByUserId
LEFT JOIN 
    PostWithVotes pwv ON pwv.UpVotes > 0 OR pwv.DownVotes > 0
GROUP BY 
    us.Id, us.DisplayName, us.Reputation, us.TotalPosts, us.TotalBadges, us.GoldBadges, us.SilverBadges, us.BronzeBadges
ORDER BY 
    AvgScore DESC, TotalUpVotes DESC
LIMIT 10;

