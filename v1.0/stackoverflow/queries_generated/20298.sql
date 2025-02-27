WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE 
            WHEN b.Class = 1 THEN 3 
            WHEN b.Class = 2 THEN 2 
            WHEN b.Class = 3 THEN 1 
            ELSE 0 END) AS TotalBadgeScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id, u.Reputation
), 
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
CloseReasonSummary AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END) AS CloseReason
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- closed or reopened
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(uv.Reputation, 0) AS UserReputation,
    COALESCE(uv.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(uv.TotalBadgeScore, 0) AS TotalUserBadgeScore,
    pc.UpVotes,
    pc.DownVotes,
    crs.CloseReason,
    CASE 
        WHEN rp.Rank <= 3 THEN 'Top Performer'
        WHEN rp.Rank IS NULL THEN 'No Ranking'
        ELSE 'Regular Performer'
    END AS PerformanceCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    UserReputation uv ON u.Id = uv.UserId
LEFT JOIN 
    PostVoteCounts pc ON rp.PostId = pc.PostId
LEFT JOIN 
    CloseReasonSummary crs ON rp.PostId = crs.PostId
WHERE 
    (rp.Score > 10 OR rp.ViewCount > 1000)
    AND (crs.CloseReason IS NULL OR crs.CloseReason <> 'Exact Duplicate') -- Filtering closed posts with specific reasons
ORDER BY 
    rp.CreationDate DESC, 
    rp.Score DESC;

### Query Breakdown
1. **Common Table Expressions (CTEs) Usage**: 
    - `RankedPosts`: Ranks posts based on their score for each post type created in the last year.
    - `UserReputation`: Aggregates users' reputations and badge counts.
    - `PostVoteCounts`: Counts upvotes and downvotes for each post.
    - `CloseReasonSummary`: Summarizes the latest close reason for each post.

2. **COALESCE**: Handles potential `NULL`s by providing a default value of zero for reputation and details.

3. **CASE Expressions**: Categorizes posts based on their ranking.

4. **FILTER clause in COUNT**: Customizes vote counts for up and down votes.

5. **Bizarre Logic**: 
    - Only posts with a score greater than 10 or view count greater than 1000 are selected. Any closed posts that are marked as 'Exact Duplicate' are filtered out.

This comprehensive query aims to provide an extensive view of top-performing posts along with user metrics and interactions, allowing for advanced analysis based on various criteria.
