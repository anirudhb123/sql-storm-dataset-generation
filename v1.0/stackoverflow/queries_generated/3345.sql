WITH UserBadges AS (
    SELECT UserId, 
           COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
           COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostDetails AS (
    SELECT p.Id AS PostId, 
           p.Title AS PostTitle, 
           p.CreationDate AS PostCreationDate, 
           u.DisplayName AS OwnerName, 
           COUNT(c.Id) AS CommentCount, 
           COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
           COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY p.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT ph.PostId,
           ph.CreationDate AS ClosedDate,
           cr.Name AS CloseReason
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment = cr.Id::text
    WHERE ph.PostHistoryTypeId = 10
)
SELECT pd.PostId, 
       pd.PostTitle, 
       pd.PostCreationDate, 
       pd.OwnerName, 
       COALESCE(ub.GoldBadges, 0) AS GoldBadges, 
       COALESCE(ub.SilverBadges, 0) AS SilverBadges, 
       COALESCE(ub.BronzeBadges, 0) AS BronzeBadges, 
       pd.CommentCount, 
       pd.UpvoteCount, 
       pd.DownvoteCount, 
       cp.ClosedDate, 
       cp.CloseReason
FROM PostDetails pd
LEFT JOIN UserBadges ub ON pd.OwnerUserId = ub.UserId
LEFT JOIN ClosedPosts cp ON pd.PostId = cp.PostId
WHERE pd.PostRank <= 5 
  AND (pd.CommentCount > 0 OR pd.UpvoteCount > 5)
ORDER BY pd.PostCreationDate DESC
FETCH FIRST 100 ROWS ONLY;
