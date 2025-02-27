WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(VoteCounts.UpVotes, 0) AS UpVotes,
        COALESCE(VoteCounts.DownVotes, 0) AS DownVotes,
        COALESCE(CommentCounts.CommentCount, 0) AS CommentCount,
        CASE 
            WHEN P.ClosedDate IS NOT NULL THEN 'Closed'
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Answered'
            ELSE 'Open'
        END AS Status,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) VoteCounts ON P.Id = VoteCounts.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) CommentCounts ON P.Id = CommentCounts.PostId
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
)
SELECT 
    U.DisplayName,
    U.Reputation,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.UpVotes,
    P.DownVotes,
    P.CommentCount,
    P.Status,
    UBadge.BadgeCount,
    P.UserPostRank
FROM PostStats P
JOIN Users U ON P.OwnerUserId = U.Id
LEFT JOIN UserBadges UBadge ON U.Id = UBadge.UserId
WHERE 
    (P.UpVotes - P.DownVotes) > 10 
    AND P.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
ORDER BY P.Score DESC, P.CreationDate DESC
LIMIT 100;

