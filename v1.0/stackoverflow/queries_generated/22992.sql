WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownvoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
),
AggregateUserData AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT rp.PostId) AS TotalPosts,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.CommentCount) AS TotalComments,
        AVG(rp.UpvoteCount - rp.DownvoteCount) AS AvgVoteDifferential,
        STRING_AGG(DISTINCT rp.Tags, ', ') AS TagsUsed
    FROM Users u
    LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY u.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
),
ExtendedUserData AS (
    SELECT 
        aud.UserId,
        aud.DisplayName,
        aud.TotalPosts,
        aud.TotalScore,
        aud.TotalComments,
        aud.AvgVoteDifferential,
        aud.TagsUsed,
        ub.BadgeCount,
        ub.BadgeNames
    FROM AggregateUserData aud
    LEFT JOIN UserBadges ub ON aud.UserId = ub.UserId
),
FinalResults AS (
    SELECT 
        eud.UserId,
        eud.DisplayName,
        eud.TotalPosts,
        eud.TotalScore,
        eud.TotalComments,
        COALESCE(eud.AvgVoteDifferential, 0) AS AvgVoteDifferential,
        eud.TagsUsed,
        CASE 
            WHEN eud.BadgeCount IS NULL THEN 'No Badges'
            WHEN eud.BadgeCount > 5 THEN 'Expert Level'
            ELSE 'Novice Level'
        END AS UserLevel
    FROM ExtendedUserData eud
)
SELECT 
    fr.*,
    CASE 
        WHEN fr.TotalPosts < 10 THEN 'Beginner'
        WHEN fr.TotalPosts BETWEEN 10 AND 50 THEN 'Intermediate'
        ELSE 'Advanced'
    END AS ExperienceLevel
FROM FinalResults fr
WHERE fr.TagsUsed IS NOT NULL
ORDER BY fr.TotalScore DESC NULLS LAST
LIMIT 100;

-- Additional performance consideration: create an index on Posts (OwnerUserId) if not present
-- to optimize the correlated subquery and the join operations.
