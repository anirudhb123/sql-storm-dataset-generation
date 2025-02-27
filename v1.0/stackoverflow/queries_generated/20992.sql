WITH UserBadges AS (
    SELECT UserId, 
           COUNT(*) AS BadgeCount,
           SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostDetails AS (
    SELECT P.Id AS PostId,
           P.Title,
           P.CreationDate,
           P.Score,
           P.ViewCount,
           COALESCE(PH.CloseReasonId, 0) AS CloseReasonId,
           U.Reputation,
           U.DisplayName AS OwnerDisplayName,
           (SELECT COUNT(*) 
            FROM Comments C 
            WHERE C.PostId = P.Id) AS CommentCount,
           (SELECT COUNT(*) 
            FROM Votes V 
            WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVoteCount
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN (
        SELECT PostId, 
               JSON_AGG(DISTINCT Comment) AS CloseReasonId
        FROM PostHistory 
        WHERE PostHistoryTypeId = 10 
        GROUP BY PostId
    ) PH ON PH.PostId = P.Id
),
PostStatistics AS (
    SELECT PD.PostId,
           PD.Title,
           PD.CreationDate,
           PD.Score,
           PD.ViewCount,
           PD.Reputation,
           PD.OwnerDisplayName,
           UB.BadgeCount,
           UB.GoldBadges,
           UB.SilverBadges,
           UB.BronzeBadges,
           PD.CommentCount,
           PD.UpVoteCount,
           RANK() OVER (ORDER BY PD.Score DESC, PD.ViewCount DESC) AS RankScore
    FROM PostDetails PD
    LEFT JOIN UserBadges UB ON PD.OwnerUserId = UB.UserId
)
SELECT *
FROM PostStatistics
WHERE RankScore <= 50
AND (GoldBadges > 2 OR SilverBadges > 3)
ORDER BY RankScore ASC, Reputation DESC;

This SQL query does the following:

1. **CTEs for User Badges**: It aggregates badge counts by user and categorizes them into gold, silver, and bronze.

2. **CTEs for Post Details**: It gathers post details such as title, creation date, score, view count, reputation of the owner, and counts of comments and upvotes.

3. **CTEs for Post Statistics**: Using the details and user badges, it ranks the posts based on score and view count.

4. **Final Selection**: The final query selects only the top 50 posts ranked by score that have either more than 2 gold badges or more than 3 silver badges, ordered by rank and reputation. 

The query showcases a mix of subqueries, CTEs, aggregates, outliers, and ranking functions, demonstrating its complexity and performance evaluation potential.
