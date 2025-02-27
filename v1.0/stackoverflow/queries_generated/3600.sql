WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 /* Questions */
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.QuestionCount,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        us.UpVotes,
        us.DownVotes,
        RANK() OVER (ORDER BY us.QuestionCount DESC, us.UpVotes DESC) AS UserRank
    FROM 
        UserStatistics us
)
SELECT 
    tu.DisplayName,
    tu.QuestionCount,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    tu.UpVotes,
    tu.DownVotes,
    rp.Title AS TopPostTitle,
    rp.ViewCount AS TopPostViews,
    rp.Score AS TopPostScore
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.PostRank = 1
WHERE 
    tu.QuestionCount > 0
ORDER BY 
    tu.UserRank
LIMIT 10;
