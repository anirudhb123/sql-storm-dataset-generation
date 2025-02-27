WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY v.CreationDate DESC) AS LatestVoteRank,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer Exists'
            ELSE 'No Accepted Answer'
        END AS AnswerStatus
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Filter for questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
), 
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(DISTINCT ph.Comment) AS CloseReasons,
        MAX(ph.CreationDate) AS LastStatusChange
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened posts
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.AnswerStatus,
    ub.BadgeNames,
    phd.CloseReasons,
    phd.LastStatusChange
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON ub.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    PostHistoryData phd ON phd.PostId = rp.PostId
WHERE 
    rp.ViewCount > 100
    AND (rp.Score > 5 OR rp.AnswerCount > 3)
    AND (phd.CloseReasons IS NULL OR phd.LastStatusChange < NOW() - INTERVAL '1 month')
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC
LIMIT 50;

### Explanation:
1. **CTEs Used**:
   - `RankedPosts`: Prepares a list of questions with details about scores, view counts, and answer counts, using `ROW_NUMBER()` to rank votes on each post.
   - `UserBadges`: Aggregates all badges for users, returning the concatenated badge names and counts per user.
   - `PostHistoryData`: Collects comments related to post closure and tracks the last status change date.

2. **MAIN SELECT**:
   - Combines data from the CTEs, their respective user badges, and the relevant post history, applying multiple filters.
   - Added predicates on the view count and scores to focus on engaging posts, while checking against closure statuses with NULL and date logic.
   
3. **ORDERING AND LIMITING**: 
   - The final output is ordered to prioritize highly viewed posts that also do well in score and comment counts, with a limitation on the total records returned.

This query robustly illustrates the use of CTEs, window functions, aggregates, and outer joins to present a complex benchmark performance use case.
