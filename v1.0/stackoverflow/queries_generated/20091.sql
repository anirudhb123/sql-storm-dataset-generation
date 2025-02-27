WITH RecursiveBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
), 
UserPostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(rbc.BadgeCount, 0) AS BadgeCount,
        COALESCE(upa.TotalPosts, 0) AS TotalPosts,
        COALESCE(upa.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(upa.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(upa.TotalScore, 0) AS TotalScore,
        COALESCE(upa.TotalViews, 0) AS TotalViews
    FROM Users u
    LEFT JOIN RecursiveBadgeCounts rbc ON u.Id = rbc.UserId
    LEFT JOIN UserPostActivity upa ON u.Id = upa.OwnerUserId
    WHERE u.Reputation > 1000 -- filter for active users
), 
RankedUsers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC, TotalPosts DESC) AS ScoreRank,
        RANK() OVER (ORDER BY BadgeCount DESC) AS BadgeRank
    FROM ActiveUsers
)
SELECT 
    au.DisplayName,
    au.BadgeCount,
    au.TotalPosts,
    au.TotalQuestions,
    au.TotalAnswers,
    au.TotalScore,
    au.TotalViews,
    CASE 
        WHEN au.BadgeCount > 0 THEN 'Badge Holder'
        ELSE 'Novice'
    END AS UserType,
    CASE 
        WHEN ScoreRank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributionLevel
FROM RankedUsers au
WHERE au.ScoreRank <= 50 
  AND au.BadgeRank <= 50
ORDER BY au.TotalScore DESC, au.BadgeCount DESC;

-- Additional analysis for posts with specific conditions alongside badge types
WITH PostScoreAnalysis AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        b.Class AS BadgeClass,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        MIN(c.CreationDate) AS FirstCommentDate
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY p.Id, p.Title, p.Score, b.Class
    HAVING COUNT(DISTINCT v.UserId) > 5 -- Only consider posts with enough votes
)
SELECT 
    psa.PostId,
    psa.Title,
    psa.Score,
    psa.VoteCount,
    psa.TotalBounty,
    CASE 
        WHEN psa.BadgeClass = 1 THEN 'Gold Badge Holder'
        WHEN psa.BadgeClass = 2 THEN 'Silver Badge Holder'
        ELSE 'No Badge'
    END AS BadgeStatus,
    CASE 
        WHEN psa.FirstCommentDate IS NOT NULL THEN 'Commented'
        ELSE 'No Comments'
    END AS CommentStatus
FROM PostScoreAnalysis psa
WHERE psa.Score > 10
ORDER BY psa.Score DESC;
