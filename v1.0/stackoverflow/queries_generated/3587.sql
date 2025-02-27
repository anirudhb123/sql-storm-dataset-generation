WITH UserBadges AS (
    SELECT UserId, 
           COUNT(*) AS BadgeCount 
    FROM Badges 
    GROUP BY UserId
), UsersWithVotes AS (
    SELECT U.Id AS UserId, 
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
), PostsWithTags AS (
    SELECT P.Id AS PostId, 
           P.Title,
           ARRAY_AGG(DISTINCT TRIM(BOTH '<>' FROM unnest(string_to_array(P.Tags, '>')))) AS TagsList,
           P.OwnerUserId,
           COUNT(C) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id
), PopularPosts AS (
    SELECT PW.PostId,
           PW.Title, 
           PW.TagsList,
           U.DisplayName AS OwnerDisplayName,
           COALESCE(UB.BadgeCount, 0) AS UserBadgeCount,
           WV.UpVotes, WV.DownVotes,
           (SELECT COUNT(*) FROM Votes V WHERE V.PostId = PW.PostId AND V.VoteTypeId = 10) AS CloseVotes
    FROM PostsWithTags PW
    JOIN Users U ON PW.OwnerUserId = U.Id
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN UsersWithVotes WV ON U.Id = WV.UserId
    WHERE PW.CommentCount > 0
), RankedPosts AS (
    SELECT PP.*, 
           RANK() OVER (ORDER BY (PP.UpVotes - PP.DownVotes) DESC) AS VoteRank
    FROM PopularPosts PP
)
SELECT RP.PostId, 
       RP.Title, 
       RP.TagsList, 
       RP.OwnerDisplayName,
       RP.UserBadgeCount,
       RP.UpVotes,
       RP.DownVotes,
       RP.CloseVotes,
       RP.VoteRank
FROM RankedPosts RP
WHERE RP.VoteRank <= 10
ORDER BY RP.VoteRank, RP.CloseVotes DESC;
