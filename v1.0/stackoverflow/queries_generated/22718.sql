WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank,
        RANK() OVER (ORDER BY p.Score DESC) AS OverallScoreRank
    FROM 
        Posts p 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    rp.Score,
    rp.UserPostRank,
    rp.OverallScoreRank,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    CASE 
        WHEN rp.Score > 100 THEN 'High Scoring'
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium Scoring'
        ELSE 'Low Scoring'
    END AS ScoreCategory,
    CASE 
        WHEN rp.CreationDate IS NOT NULL THEN 
            DATEDIFF(NOW(), rp.CreationDate)
        ELSE 
            NULL 
    END AS DaysSinceCreation
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteStats pvs ON rp.PostId = pvs.PostId
LEFT JOIN 
    Users u ON rp.UserPostRank = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    (rp.ViewCount IS NOT NULL OR rp.ViewCount > 10) 
    AND (rp.UserPostRank IS NOT NULL OR rp.UserPostRank < 5)
ORDER BY 
    rp.OverallScoreRank DESC,
    ScoreCategory ASC
LIMIT 50
OFFSET COALESCE((SELECT COUNT(*) FROM Posts WHERE Score IS NOT NULL), 0) / 2
;

### Explanation
1. **CTEs (Common Table Expressions)**: 
   - `RankedPosts` creates ranks for each post based on score within user groups and overall ranks.
   - `PostVoteStats` aggregates vote counts for posts (upvotes and downvotes).
   - `UserBadges` counts the different types of badges a user has earned.

2. **Joins**:
   - The main query selects from the `RankedPosts` CTE and joins with `PostVoteStats` and `UserBadges` to enrich the data with user contributions and vote statistics.

3. **Case Statements**:
   - Classifies posts based on their score into 'High', 'Medium', or 'Low' categories, utilizing different logic paths for determining 'DaysSinceCreation.'

4. **NULL Logic**:
   - `COALESCE` is used to handle potential NULL values in the aggregate results from the CTEs.

5. **Complex Predicate Logic**:
   - The `WHERE` clause handles multiple conditions both for `ViewCount` and `UserPostRank`.

6. **Pagination**:
   - The query also demonstrates pagination logic using `LIMIT` and `OFFSET` to retrieve a specific subset of results, accounting for a dynamically calculated offset based on posts count.

This query is designed to test the performance of various SQL features coherently within a complex situation of real-world data scenarios.
