
WITH UserVotes AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
), 
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(*) AS GoldBadges,
        COUNT(*) AS SilverBadges,
        COUNT(*) AS BronzeBadges
    FROM 
        Badges b
    WHERE 
        b.Class IN (1, 2, 3)
    GROUP BY 
        b.UserId
), 
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
), 
ClosedPosts AS (
    SELECT 
        ph.UserId, 
        COUNT(DISTINCT ph.PostId) AS ClosedPostCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ISNULL(uv.UpVotes, 0) AS UpVotes,
    ISNULL(uv.DownVotes, 0) AS DownVotes,
    ISNULL(ub.GoldBadges, 0) AS GoldBadges,
    ISNULL(ub.SilverBadges, 0) AS SilverBadges,
    ISNULL(ub.BronzeBadges, 0) AS BronzeBadges,
    ISNULL(ps.TotalPosts, 0) AS TotalPosts,
    ISNULL(ps.AvgScore, 0) AS AvgScore,
    ISNULL(ps.Questions, 0) AS Questions,
    ISNULL(ps.Answers, 0) AS Answers,
    ISNULL(cp.ClosedPostCount, 0) AS ClosedPosts
FROM 
    Users u
LEFT JOIN 
    UserVotes uv ON u.Id = uv.UserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    ClosedPosts cp ON u.Id = cp.UserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
