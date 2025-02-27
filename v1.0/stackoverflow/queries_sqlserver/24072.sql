
WITH BadgesSummary AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS PositiveScore,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY SUM(p.ViewCount) DESC) AS ViewRank
    FROM Posts p
    WHERE p.CreationDate >= CAST(GETDATE() AS DATE) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
UserVotingStats AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN v.VoteTypeId IN (2, 4) THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Votes v
    GROUP BY v.UserId
),
CombinedResults AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        bs.GoldBadges,
        bs.SilverBadges,
        bs.BronzeBadges,
        pa.PostCount,
        pa.TotalViews,
        pa.PositiveScore,
        uv.TotalUpVotes,
        uv.TotalDownVotes,
        CASE 
            WHEN ISNULL(bs.TotalBadges, 0) >= ISNULL(pa.PostCount, 0) AND ISNULL(uv.TotalUpVotes, 0) - ISNULL(uv.TotalDownVotes, 0) >= ISNULL(bs.TotalBadges, 0) THEN ISNULL(bs.TotalBadges, 0) 
            WHEN ISNULL(pa.PostCount, 0) >= ISNULL(bs.TotalBadges, 0) AND ISNULL(uv.TotalUpVotes, 0) - ISNULL(uv.TotalDownVotes, 0) >= ISNULL(pa.PostCount, 0) THEN ISNULL(pa.PostCount, 0)
            ELSE ISNULL(uv.TotalUpVotes, 0) - ISNULL(uv.TotalDownVotes, 0)
        END AS PerformanceMetric
    FROM Users u
    LEFT JOIN BadgesSummary bs ON u.Id = bs.UserId
    LEFT JOIN PostActivity pa ON u.Id = pa.OwnerUserId
    LEFT JOIN UserVotingStats uv ON u.Id = uv.UserId
)
SELECT 
    UserId,
    DisplayName,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostCount,
    TotalViews,
    PositiveScore,
    TotalUpVotes,
    TotalDownVotes,
    PerformanceMetric
FROM CombinedResults
WHERE PerformanceMetric IS NOT NULL
ORDER BY PerformanceMetric DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
