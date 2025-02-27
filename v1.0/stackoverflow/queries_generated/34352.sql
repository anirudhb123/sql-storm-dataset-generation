WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Fetching top-level questions
    UNION ALL
    SELECT 
        a.Id,
        a.Title,
        a.CreationDate,
        a.Score,
        a.OwnerUserId,
        a.AcceptedAnswerId,
        r.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursiveCTE r ON a.ParentId = r.PostId
    WHERE 
        a.PostTypeId = 2 -- Fetching answers to those questions
), 
VoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Votes
    GROUP BY 
        PostId
), 
BadgeAggregate AS (
    SELECT
        UserId,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    q.PostId,
    q.Title,
    q.CreationDate,
    COALESCE(v.Upvotes, 0) AS TotalUpvotes,
    COALESCE(v.Downvotes, 0) AS TotalDownvotes,
    COALESCE(b.TotalBadges, 0) AS UserTotalBadges,
    COALESCE(b.GoldBadges, 0) AS UserGoldBadges,
    COALESCE(b.SilverBadges, 0) AS UserSilverBadges,
    COALESCE(b.BronzeBadges, 0) AS UserBronzeBadges,
    q.Level
FROM 
    RecursiveCTE q
LEFT JOIN 
    VoteCounts v ON q.PostId = v.PostId
LEFT JOIN 
    BadgeAggregate b ON q.OwnerUserId = b.UserId
WHERE 
    (q.Score > 10 OR (EXISTS (
        SELECT 1 
        FROM Comments c 
        WHERE c.PostId = q.PostId AND c.Score < 0
    )))
ORDER BY 
    q.CreationDate DESC, 
    q.Score DESC;
This SQL query accomplishes several tasks:

1. **Recursive Common Table Expression (CTE)**: It builds a hierarchy of questions and their corresponding answers.
2. **Vote Counting**: It counts the total upvotes and downvotes for each post.
3. **Badge Aggregation**: It computes the total badges and the breakdown by type (Gold, Silver, Bronze) for each user.
4. **Complex Filtering**: It filters posts based on a score threshold or comments indicating negative feedback.
5. **NULL Handling**: It uses `COALESCE` to convert possible NULL values from joins into counts of zero.
6. **Sorting**: Finally, it orders results based on creation date and score, producing a well-structured output for analysis.
