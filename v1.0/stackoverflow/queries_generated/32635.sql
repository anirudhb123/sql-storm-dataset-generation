WITH RecursiveVoteCTE AS (
    SELECT V.PostId, V.UserId, V.VoteTypeId, 1 AS Level
    FROM Votes V
    WHERE V.VoteTypeId IN (2, 3)  -- considering only upvotes and downvotes
    UNION ALL
    SELECT V.PostId, V.UserId, V.VoteTypeId, R.Level + 1
    FROM Votes V
    INNER JOIN RecursiveVoteCTE R ON V.UserId = R.UserId AND V.PostId <> R.PostId
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT H.UserId) AS UserVotes
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN RecursiveVoteCTE R ON P.Id = R.PostId
    LEFT JOIN PostHistory H ON P.Id = H.PostId AND H.CreationDate >= CURRENT_DATE - INTERVAL '30 days'  -- edits in the last 30 days
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY P.Id, P.OwnerUserId, P.Title
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.UpVotes,
    PS.DownVotes,
    PS.CommentCount,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    (PS.UpVotes - PS.DownVotes) AS NetVotes,
    CASE 
        WHEN PS.UserVotes > 0 THEN 'Active Voter'
        ELSE 'Inactive Voter'
    END AS VotingStatus
FROM PostStats PS
LEFT JOIN UserBadges UB ON PS.OwnerUserId = UB.UserId
ORDER BY NetVotes DESC, PS.CommentCount DESC;
