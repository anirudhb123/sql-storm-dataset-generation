WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 -- Questions only
        AND p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts from the last year
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS TotalUpvotes
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
),
RecentActivity AS (
    SELECT
        pho.UserId,
        COUNT(*) AS HistoryCount,
        MAX(pho.CreationDate) AS LastActivityDate
    FROM
        PostHistory pho
    WHERE
        pho.CreationDate >= DATEADD(month, -6, GETDATE()) -- Activity in the last 6 months
    GROUP BY
        pho.UserId
)
SELECT
    u.DisplayName,
    u.Reputation,
    us.QuestionCount,
    us.TotalBadges,
    us.TotalBounty,
    us.TotalUpvotes,
    ra.HistoryCount,
    ra.LastActivityDate,
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate AS PostCreationDate,
    rp.ViewCount,
    rp.Score
FROM
    Users u
LEFT JOIN
    UserStats us ON u.Id = us.UserId
LEFT JOIN
    RecentActivity ra ON u.Id = ra.UserId
LEFT JOIN
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.RankByUser = 1 -- Get the most recent question from each user
WHERE
    (us.QuestionCount > 5 OR us.Reputation > 100) -- Filter users with a significant presence
ORDER BY
    us.Reputation DESC, -- Order by reputation
    ra.LastActivityDate DESC; -- then by last activity
