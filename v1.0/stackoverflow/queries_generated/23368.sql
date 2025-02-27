WITH UserVotes AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN (CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE -1 END) ELSE 0 END) AS VoteBalance,
        ROW_NUMBER() OVER (PARTITION BY u.Reputation ORDER BY COUNT(v.VoteTypeId) DESC) AS VoteRank
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.Reputation IS NOT NULL 
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentsCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY p.Id
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentsCount,
        ps.GoldBadges,
        ps.SilverBadges,
        ps.BronzeBadges,
        ps.TotalBadges,
        DENSE_RANK() OVER (ORDER BY ps.CommentsCount DESC, ps.TotalBadges DESC) AS PostRank
    FROM PostStats ps
)
SELECT 
    uv.DisplayName,
    rp.Title,
    rp.CommentsCount,
    rp.GoldBadges,
    rp.SilverBadges,
    rp.BronzeBadges,
    uv.VoteBalance,
    CASE 
        WHEN rp.PostRank <= 10 THEN 'Top Posts'
        ELSE 'Other Posts'
    END AS PostCategory
FROM RankedPosts rp
JOIN UserVotes uv ON uv.UserId = (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = rp.PostId)
WHERE uv.VoteBalance > 0
    AND rp.CommentsCount < (SELECT AVG(CommentsCount) FROM PostStats)
    AND rp.GoldBadges IS NOT NULL
ORDER BY uv.VoteBalance DESC, rp.CommentsCount ASC
LIMIT 20;

This SQL query performs an elaborate performance benchmark involving several advanced constructs. It begins by establishing a CTE to aggregate user voting data, including counts of upvotes and downvotes along with a vote balance that calculates the overall impact of a user's votes.

Additionally, a second CTE aggregates details about posts created within the past year, including comment counts and badge totals for the post owners. This data subsequently feeds into another CTE that ranks posts based on their interaction metrics.

Finally, the primary selection retrieves the top users linked to underperforming posts with respect to comment counts and filters based on positive vote balances, aiming to identify potentially impactful interactions within the community while applying business logic using a combined CASE statement. The results prioritize presentation with an ascending and descending order on vote balances and comment counts, respectively.
