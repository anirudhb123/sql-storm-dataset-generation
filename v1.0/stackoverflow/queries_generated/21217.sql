WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 AND
        p.Score >= 0
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadge
    FROM
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
PostWithBadges AS (
    SELECT
        rp.PostId,
        rp.Title,
        rb.BadgeCount,
        rb.HighestBadge,
        rp.CreationDate,
        CASE
            WHEN rb.BadgeCount > 0 THEN 'Has Badges'
            ELSE 'No Badges'
        END AS BadgeStatus
    FROM
        RankedPosts rp
    LEFT JOIN UserBadges rb ON rp.OwnerUserId = rb.UserId
)
SELECT
    p.Title,
    p.CreationDate,
    p.Score,
    p.BadgeStatus,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    ARRAY_AGG(t.TagName) AS Tags,
    ARRAY_AGG(DISTINCT vt.Name) AS VoteTypes
FROM
    PostWithBadges p
LEFT JOIN (
    SELECT
        PostId,
        COUNT(*) AS CommentCount
    FROM
        Comments
    GROUP BY
        PostId
) c ON p.PostId = c.PostId
LEFT JOIN Posts ps ON ps.Id = p.PostId
LEFT JOIN STRING_TO_ARRAY(substring(ps.Tags, 2, length(ps.Tags) - 2), '><') AS t ON TRUE
LEFT JOIN Votes v ON v.PostId = p.PostId
LEFT JOIN VoteTypes vt ON vt.Id = v.VoteTypeId
WHERE
    (p.BadgeStatus = 'Has Badges' AND p.HighestBadge = 1) OR
    (p.Score > 10 AND p.BadgeStatus = 'No Badges')
GROUP BY
    p.Title, p.CreationDate, p.Score, p.BadgeStatus, c.CommentCount
ORDER BY
    p.Score DESC NULLS LAST, p.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;

### Explanation:
1. **RankedPosts CTE**: 
   - Selects posts of type "Question" where the score is non-negative. 
   - Ranks them based on their score for each user.

2. **UserBadges CTE**: 
   - Counts the number of badges a user has and finds the highest badge class.

3. **PostWithBadges CTE**: 
   - Combines `RankedPosts` with `UserBadges` to add badge information.

4. **Final Selection**: 
   - Retrieves the most relevant post data including the title, creation date, score, badge status, comment count, associated tags, and voting types.
   - The filtering logic selectively fetches posts based on badge status and score.
   - Groups results by relevant fields, ensuring aggregation of comments and tags.

5. **Complexity Elements**:
   - The use of CTEs, window functions (ROW_NUMBER), COALESCE for null handling, string functions to parse tags, and various joins enhance the complexity and performance aspects of this query. 

6. **Ordering and Fetching**:
   - Orders by score and creation date, ensuring a maximum of 100 rows are returned, adding further performance considerations while evaluating logical conditions and edge cases in badge handling.
