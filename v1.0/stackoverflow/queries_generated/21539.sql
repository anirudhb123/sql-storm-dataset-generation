WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= now() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(RP.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(RP.Upvotes), 0) AS TotalUpvotes,
        COALESCE(SUM(RP.Downvotes), 0) AS TotalDownvotes,
        COUNT(DISTINCT RP.PostId) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts RP ON u.Id = RP.OwnerUserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalViews,
        TotalUpvotes,
        TotalDownvotes,
        PostCount,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserStats
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalViews,
    tu.TotalUpvotes,
    tu.TotalDownvotes,
    tu.PostCount,
    CASE 
        WHEN tu.PostCount > 0 THEN ROUND((tu.TotalUpvotes::decimal / (tu.TotalUpvotes + tu.TotalDownvotes + NULLIF(tu.TotalDownvotes, 0))) * 100, 2)
        ELSE NULL 
    END AS UpvotePercentage,
    CASE 
        WHEN tu.Reputation > 1000 AND tu.PostCount > 10 THEN 'Gold Contributor'
        WHEN tu.Reputation > 500 THEN 'Silver Contributor'
        ELSE 'Bronze Contributor'
    END AS ContributionLevel
FROM 
    TopUsers tu
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.UserRank;

-- Additional queries that leverage the results to find patterns in their post behavior
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CommentCount,
    rp.TotalBounty,
    CASE 
        WHEN rp.RankByScore = 1 THEN 'Top Post'
        WHEN rp.RankByScore <= 5 THEN 'High Scoring Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts rp
WHERE 
    rp.CommentCount > 3
    AND (rp.Upvotes - rp.Downvotes) > 5
ORDER BY 
    rp.ViewCount DESC, rp.TotalBounty DESC;

-- Identifying the unique attributes of posts that have been migrated
SELECT 
    p.Id AS PostId,
    p.Title,
    ph.CreationDate,
    ph.Comment,
    ht.Name AS HistoryType
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
WHERE 
    ht.Name LIKE '%Migrated%' 
    AND ph.CreationDate >= now() - INTERVAL '6 months'
ORDER BY 
    ph.CreationDate DESC;

This SQL query demonstrates various complex constructs including Common Table Expressions (CTEs), window functions, outer joins, and calculations. The first part aggregates post information per user, ranks users by reputation, and calculates the upvote percentage, while determining contribution levels based on reputation and post count. The next query filters for high-engagement posts and categorizes them. The final query retrieves posts with migration history in the last six months.
