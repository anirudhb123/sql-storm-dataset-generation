WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVotes,
        COALESCE(NULLIF(COUNT(c.Id), 0), 0) AS CommentCount
    FROM
        Posts p
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        SUM(rp.CommentCount) AS TotalComments
    FROM
        Users u
    LEFT JOIN
        RankedPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
QualifiedBadges AS (
    SELECT
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM
        Badges b
    WHERE
        b.Class = 1 -- Only Gold badges
    GROUP BY
        b.UserId
),
FinalStats AS (
    SELECT
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.TotalViews,
        us.TotalScore,
        us.TotalComments,
        qb.BadgeNames
    FROM
        UserStats us
    LEFT JOIN
        QualifiedBadges qb ON us.UserId = qb.UserId
    WHERE
        us.TotalPosts > 5 -- Filtering out users with low post counts
        AND us.TotalScore > 10 -- Ensuring users have meaningful scores
)
SELECT
    CAST(f.DisplayName AS varchar(40)) AS DisplayName,
    f.Reputation,
    f.TotalPosts,
    f.TotalViews,
    f.TotalScore,
    f.TotalComments,
    COALESCE(f.BadgeNames, 'No Gold Badges') AS BadgeNames,
    CASE
        WHEN f.TotalComments = 0 THEN 'No Comments Yet'
        WHEN f.TotalComments BETWEEN 1 AND 5 THEN 'New Commenter'
        ELSE 'Active Commenter'
    END AS CommentActivity,
    CASE
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.UserId = f.UserId AND v.VoteTypeId IN (2, 3)) 
        THEN 'Has Voted'
        ELSE 'No Votes Recorded'
    END AS VotingActivity
FROM
    FinalStats f
ORDER BY
    f.TotalScore DESC, f.Reputation DESC NULLS LAST
LIMIT 100;
