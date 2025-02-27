WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(DISTINCT v.Id) OVER (PARTITION BY p.Id) AS VoteCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  -- Upvotes and downvotes
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
AggregatedPostCounts AS (
    SELECT 
        OwnerUserId,
        SUM(CASE WHEN PostRank = 1 THEN 1 ELSE 0 END) AS LatestPostCount,
        SUM(CASE WHEN PostRank > 1 THEN 1 ELSE 0 END) AS OlderPostCount
    FROM 
        RankedPosts
    GROUP BY 
        OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(a.LatestPostCount, 0) AS LatestPosts,
        COALESCE(a.OlderPostCount, 0) AS OlderPosts
    FROM 
        Users u
    LEFT JOIN 
        AggregatedPostCounts a ON u.Id = a.OwnerUserId
    WHERE 
        u.Reputation > 1000
    ORDER BY 
        u.Reputation DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.LatestPosts,
    tu.OlderPosts,
    STRING_AGG(DISTINCT p.Tags, ', ') AS TagsUsed,
    SUM(COALESCE(p.Score, 0)) AS TotalScore,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
    COUNT(DISTINCT c.Id) AS TotalComments
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    tu.DisplayName, tu.Reputation, tu.LatestPosts, tu.OlderPosts
ORDER BY 
    TotalScore DESC;
