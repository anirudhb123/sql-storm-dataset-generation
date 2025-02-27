WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
    AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(s.UpVotes, 0) AS TotalUpVotes,
    COALESCE(s.DownVotes, 0) AS TotalDownVotes,
    COALESCE(b.GoldBadges, 0) AS GoldBadges,
    COALESCE(b.SilverBadges, 0) AS SilverBadges,
    COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    SUM(CASE WHEN rp.rn = 1 THEN 1 ELSE 0 END) AS RecentQuestions,
    AVG(rp.ViewCount) AS AvgViewCount
FROM 
    Users u
LEFT JOIN 
    PostVoteSummary s ON u.Id = s.PostId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
GROUP BY 
    u.Id, u.DisplayName, b.GoldBadges, b.SilverBadges, b.BronzeBadges
ORDER BY 
    TotalUpVotes DESC, AvgViewCount DESC
LIMIT 10;
