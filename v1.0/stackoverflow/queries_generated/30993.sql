WITH RecursiveTagCounts AS (
    SELECT
        Id,
        TagName,
        COUNT(*) AS PostCount
    FROM
        Tags t
        JOIN Posts p ON t.Id = p.Id
    GROUP BY
        t.Id, t.TagName
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
ClosedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        ph.CreationDate,
        ph.UserDisplayName AS ClosedBy,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM
        Posts p
        JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
        LEFT JOIN CloseReasonTypes crt ON CRT.Id = CAST(ph.Comment AS INT)
    WHERE
        p.CreationDate < NOW() - INTERVAL '1 year'
    GROUP BY
        p.Id, p.Title, ph.CreationDate, ph.UserDisplayName
),
UserPostScores AS (
    SELECT
        u.Id,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id
),
RankedUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ups.TotalScore,
        ROW_NUMBER() OVER (ORDER BY ups.TotalScore DESC) AS Rank
    FROM
        Users u
        JOIN UserBadges ub ON u.Id = ub.UserId
        JOIN UserPostScores ups ON u.Id = ups.Id
)
SELECT 
    ru.Rank,
    ru.DisplayName,
    ru.GoldBadges,
    ru.SilverBadges,
    ru.BronzeBadges,
    ru.TotalScore,
    COALESCE(ctc.PostCount, 0) AS TagCount,
    cp.Title AS ClosedPostTitle,
    cp.CloseReasons
FROM 
    RankedUsers ru
    LEFT JOIN RecursiveTagCounts ctc ON ctc.PostCount > 0
    LEFT JOIN ClosedPosts cp ON cp.ClosedBy = ru.DisplayName
WHERE 
    ru.TotalScore > 1000 
ORDER BY 
    ru.Rank, ru.DisplayName;

