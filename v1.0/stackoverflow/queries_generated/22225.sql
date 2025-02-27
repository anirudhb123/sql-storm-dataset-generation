WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
        AND p.Score IS NOT NULL
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(MAX(rp.Score), 0) AS MaxScore,
        SUM(COALESCE(rp.Score, 0)) AS TotalScore,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        CASE 
            WHEN SUM(COALESCE(rp.Score, 0)) > 0 THEN 'Active'
            ELSE 'Inactive'
        END AS ActivityStatus
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    GROUP BY 
        u.Id, u.DisplayName, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
),
PostInteraction AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) FILTER (WHERE v.VoteTypeId = 8) AS TotalBounty,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
FinalAnalysis AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        tu.MaxScore,
        tu.TotalScore,
        tu.GoldBadges,
        tu.SilverBadges,
        tu.BronzeBadges,
        pi.PostId,
        pi.CommentCount,
        pi.TotalBounty,
        pi.UpVotes,
        pi.DownVotes
    FROM 
        TopUsers tu
    JOIN 
        PostInteraction pi ON tu.UserId = pi.PostId
    ORDER BY 
        tu.TotalScore DESC, pi.CommentCount DESC
)
SELECT 
    *,
    CASE 
        WHEN TotalScore = 0 THEN 'No Activity'
        WHEN TotalBounty > 0 THEN 'Has Bounties'
        ELSE 'Regular User'
    END AS UserType,
    CASE 
        WHEN MaxScore IS NULL THEN 'No Posts'
        WHEN MaxScore > 10 THEN 'High Achiever'
        ELSE 'Just Getting Started'
    END AS UserAchievement
FROM 
    FinalAnalysis
WHERE 
    ActivityStatus = 'Active' 
    AND (CommentCount > 5 OR UpVotes > 5)
ORDER BY 
    UserAchievement, TotalScore DESC;
This SQL query is quite elaborate and incorporates several advanced constructs such as Common Table Expressions (CTEs), window functions, conditional aggregations and filters, as well as multiple joins and subqueries. It ultimately generates a report of active users based on their post interactions, scores, and badge counts, allowing for nuanced analysis of engagement on a platform resembling StackOverflow.
