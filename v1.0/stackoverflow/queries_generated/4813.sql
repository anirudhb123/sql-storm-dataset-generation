WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RankedEngagement AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalVotes DESC) AS EngagementRank
    FROM 
        UserEngagement
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        TotalVotes,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        EngagementRank
    FROM 
        RankedEngagement
    WHERE 
        EngagementRank <= 50
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    COALESCE(tu.TotalPosts, 0) AS Posts,
    COALESCE(tu.TotalComments, 0) AS Comments,
    COALESCE(tu.TotalVotes, 0) AS Votes,
    CONCAT_WS(', ', 
        CASE WHEN tu.GoldBadges > 0 THEN CONCAT(tu.GoldBadges, ' Gold') ELSE NULL END,
        CASE WHEN tu.SilverBadges > 0 THEN CONCAT(tu.SilverBadges, ' Silver') ELSE NULL END,
        CASE WHEN tu.BronzeBadges > 0 THEN CONCAT(tu.BronzeBadges, ' Bronze') ELSE NULL END
    ) AS BadgeSummary
FROM 
    TopUsers tu
ORDER BY 
    tu.Reputation DESC;
