WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeCount,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount, 
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
),
RankedPosts AS (
    SELECT 
        pd.*,
        ubc.TotalBadges,
        CASE 
            WHEN pd.Score > 100 THEN 'High Score'
            WHEN pd.Score BETWEEN 50 AND 100 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM PostDetails pd
    JOIN UserBadgeCounts ubc ON pd.OwnerUserId = ubc.UserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(rp.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(rp.Score), 0) AS TotalScore,
        COUNT(DISTINCT rp.PostId) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN rp.ScoreCategory = 'High Score' THEN rp.PostId END) AS HighScorePosts,
        MAX(rp.UserPostRank) AS HighestPostRank
    FROM Users u
    LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY u.Id
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalViews,
    up.TotalScore,
    up.TotalPosts,
    up.HighScorePosts,
    CASE 
        WHEN up.TotalPosts = 0 THEN 'No Posts'
        ELSE 'Active Contributors'
    END AS ContributionStatus,
    COALESCE(bu.Reputation, 0) AS UserReputation,
    CASE 
        WHEN bu.CreationDate < NOW() - INTERVAL '5 years' THEN 'Long-Term User'
        ELSE 'Newer User'
    END AS UserTenure,
    STRING_AGG(DISTINCT COALESCE(t.TagName, 'No Tags'), ', ') AS UsedTags
FROM UserPerformance up
JOIN Users bu ON up.UserId = bu.Id
LEFT JOIN Posts p ON p.OwnerUserId = up.UserId
LEFT JOIN LATERAL (
    SELECT 
        unnest(string_to_array(p.Tags, ',')) AS TagName
    ) t ON true
GROUP BY up.UserId, up.DisplayName, bu.Reputation, bu.CreationDate
ORDER BY up.TotalScore DESC, up.TotalViews DESC
LIMIT 50;
