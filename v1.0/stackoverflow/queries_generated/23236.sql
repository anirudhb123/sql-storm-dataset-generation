WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(p.OwnerUserId, -1) AS OwnerUserId,
        u.Reputation AS OwnerReputation,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON ph.Comment::int = ctr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        MAX(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadge,
        MAX(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadge,
        MAX(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadge
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerUserId,
    COALESCE(ub.BadgeCount, 0) AS NumberOfBadges,
    rp.OwnerReputation,
    COALESCE(pvc.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pvc.DownVotes, 0) AS TotalDownVotes,
    cr.CloseReasonNames,
    CASE 
        WHEN rp.RecentPostRank = 1 THEN 'Most Recent Post'
        ELSE CONCAT('Poster has ', rp.RecentPostRank, ' recent posts')
    END AS PostStatus,
    CASE 
        WHEN rp.OwnerReputation < 100 THEN 'Low Reputation' 
        WHEN rp.OwnerReputation BETWEEN 100 AND 1000 THEN 'Medium Reputation'
        ELSE 'High Reputation'
    END AS ReputationCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteCounts pvc ON rp.PostId = pvc.PostId
LEFT JOIN 
    CloseReasons cr ON rp.PostId = cr.PostId
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.RecentPostRank <= 3
ORDER BY 
    rp.CreationDate DESC;

### Explanation of the Query:

1. **CTE `RankedPosts`:** Retrieves the most recent posts from users who have posted within the last year, ranking them per user by the creation date.

2. **CTE `PostVoteCounts`:** Aggregates upvotes and downvotes for each post.

3. **CTE `CloseReasons`:** Gathers the distinct close reasons for closed posts.

4. **CTE `UserBadges`:** Counts the number of badges for each user and also categorizes their badges into gold, silver, and bronze.

5. **Final Selection:** Combines all the CTEs to provide a detailed overview of each post, including title, owner information, vote counts, close reason names, status, and reputation category.

6. **Use of **NULL Logic**: The use of `COALESCE` also demonstrates handling of NULLs across multiple joins.

7. **String Aggregation:** The selection of close reason names uses string aggregation to consolidate multiple reasons into a single field.

This complex query incorporates various SQL features such as outer joins, window functions, CTEs, string expressions, conditional logic, and various predicate checks, making it well-suited for performance benchmarking.
