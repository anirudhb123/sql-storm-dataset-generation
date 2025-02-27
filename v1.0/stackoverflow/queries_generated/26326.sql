WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Score,
        p.ViewCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.PostTypeId = 1 -- Only consider Questions
        AND p.CreationDate > CURRENT_DATE - INTERVAL '1 year' -- Posts from the last year
    GROUP BY 
        p.Id, p.Title, p.Body, p.Score, p.ViewCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopContributors AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalScore,
        us.TotalPosts,
        us.TotalBadges,
        ROW_NUMBER() OVER (ORDER BY us.TotalScore DESC, us.TotalPosts DESC) AS ContributionRank
    FROM 
        UserStats us
    WHERE 
        us.TotalPosts > 5 -- Only considering users with more than 5 questions
)
SELECT 
    rc.PostId,
    rc.Title,
    rc.Body,
    rc.Score,
    rc.ViewCount,
    rc.Tags,
    tc.DisplayName AS TopContributor,
    tc.TotalScore AS ContributorScore,
    tc.TotalPosts AS ContributorPosts,
    tc.TotalBadges AS ContributorBadges
FROM 
    RankedPosts rc
JOIN 
    TopContributors tc on rc.PostRank = 1 -- Get the top contributor for each user's top post
ORDER BY 
    rc.Score DESC, rc.ViewCount DESC
LIMIT 10; -- Limit to the top 10 posts
