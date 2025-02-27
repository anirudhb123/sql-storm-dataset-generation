WITH PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 1 THEN v.Id END) AS AcceptedVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UserUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS UserDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostClosureReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 'Closed: ' || cr.Name
            WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Unknown action'
        END, ', ') AS ClosureReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON (ph.Comment IS NOT NULL AND CAST(ph.Comment AS INTEGER) = cr.Id)
    GROUP BY 
        ph.PostId
),
RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.LastActivityDate,
        p.Score,
        COALESCE(pvs.UpVotes, 0) AS UpVotes,
        COALESCE(pvs.DownVotes, 0) AS DownVotes,
        COALESCE(u.BadgeCount, 0) AS UserBadges,
        COALESCE(crs.ClosureReasons, 'No closure reasons') AS ClosureReasons,
        ROW_NUMBER() OVER (ORDER BY p.LastActivityDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteStats pvs ON p.Id = pvs.PostId
    LEFT JOIN 
        UserReputation u ON p.OwnerUserId = u.UserId
    LEFT JOIN 
        PostClosureReasons crs ON p.Id = crs.PostId
)
SELECT 
    rp.Rank,
    rp.Title,
    rp.UpVotes,
    rp.DownVotes,
    rp.UserBadges,
    rp.ClosureReasons
FROM 
    RankedPosts rp
WHERE 
    rp.UpVotes > rp.DownVotes 
    AND rp.UserBadges > 0 
    AND rp.Score IS NOT NULL
ORDER BY 
    rp.Rank
FETCH FIRST 10 ROWS ONLY;

This SQL query achieves several complex operations while addressing various aspects of the schema:

1. **Common Table Expressions (CTEs)**: 
   - `PostVoteStats` aggregates vote counts per post.
   - `UserReputation` captures user reputation alongside badge counts and vote types.
   - `PostClosureReasons` retrieves closure reasons for posts with conditions on historical actions.

2. **Window Functions**: 
   - Ranks posts based on their last activity, allowing for easy selection of the top-performing posts.

3. **Outer Joins**: 
   - Various left joins ensure we still capture posts even when associated data may be missing.

4. **Complicated Predicates**:
   - Multi-faceted filtering based on multiple conditions related to votes and badges.

5. **String Aggregation**:
   - Uses `STRING_AGG` to handle closure reasons and represents them cleanly in a single column.

6. **NULL Logic**:
   - COALESCE function ensures that relevant fields are populated even if related data is absent.

7. **Ranked Selection**:
   - The final selection returns only the top 10 posts satisfying the conditions, demonstrating effective use of ranking and limit clauses.

What results emerges is a performance benchmark of the posts highlighting their interaction dynamics without losing essential linked data, an intriguing mix of data relationships expected from a StackOverflow-like environment.
