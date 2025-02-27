WITH RecursiveBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS BadgeRank
    FROM Badges
    GROUP BY UserId
),
QuestionPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ViewCount,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS UpVoteCount
        FROM Votes
        WHERE VoteTypeId = 2 -- UpMod
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1
),
ClosedQuestions AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate
    FROM PostHistory ph
    GROUP BY ph.PostId
),
RankedQuestions AS (
    SELECT 
        qp.PostId,
        qp.Title,
        qp.OwnerUserId,
        qp.ViewCount,
        qp.UpVoteCount,
        qp.CommentCount,
        ROW_NUMBER() OVER (ORDER BY qp.ViewCount DESC, qp.UpVoteCount DESC) AS Rank
    FROM QuestionPosts qp
    LEFT JOIN ClosedQuestions cq ON qp.PostId = cq.PostId
    WHERE cq.ClosedDate IS NULL
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        CONCAT(u.DisplayName, ' - Reputation: ', to_char(u.Reputation, 'FM999,999,999')) AS UserInfo,
        rb.BadgeCount AS BadgeCount
    FROM Users u
    JOIN RecursiveBadgeCounts rb ON u.Id = rb.UserId
    WHERE rb.BadgeCount > 0
)
SELECT 
    rq.Rank,
    rq.Title,
    rq.ViewCount,
    rq.UpVoteCount,
    rq.CommentCount,
    u.UserInfo
FROM RankedQuestions rq
JOIN UsersWithBadges u ON rq.OwnerUserId = u.UserId
WHERE rq.Rank <= 10
ORDER BY rq.Rank;

### Explanation:
1. **RecursiveBadgeCounts CTE**: An aggregate table that counts badges by users and ranks them.
2. **QuestionPosts CTE**: Combines post information related to questions with their associated comment and upvote counts, using `LEFT JOIN` for votes and comments.
3. **ClosedQuestions CTE**: Determines which posts have been closed by checking the `PostHistory` for the corresponding records.
4. **RankedQuestions CTE**: Ranks the active questions that are not closed based on view counts and upvotes.
5. **UsersWithBadges CTE**: Fetches user info and badge counts for users who have earned badges.
6. **Final SELECT statement**: Joins the ranked questions with user information to get the top 10 ranked active questions along with the details of their owners.
