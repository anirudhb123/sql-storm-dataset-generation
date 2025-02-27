WITH UserBadges AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           COUNT(B.Id) AS TotalBadges,
           SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PopularTags AS (
    SELECT unnest(string_to_array(Tags, '>')) AS Tag
    FROM Posts
    WHERE PostTypeId = 1
),
TagUsage AS (
    SELECT Tag,
           COUNT(*) AS UsageCount
    FROM PopularTags
    GROUP BY Tag
    ORDER BY UsageCount DESC
    LIMIT 10
),
PostDetails AS (
    SELECT P.Id AS PostId,
           P.Title,
           P.OwnerUserId,
           COUNT(C.Id) AS CommentCount,
           COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVotes,
           COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVotes,
           PT.Name AS PostType
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN PostTypes PT ON P.PostTypeId = PT.Id
    WHERE P.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY P.Id, P.Title, P.OwnerUserId, PT.Name
),
FinalReport AS (
    SELECT U.DisplayName,
           UB.TotalBadges,
           UB.GoldBadges,
           UB.SilverBadges,
           UB.BronzeBadges,
           PD.PostId,
           PD.Title,
           PD.CommentCount,
           PD.UpVotes,
           PD.DownVotes,
           PT TagUsage.Tag AS PopularTag,
           T.UsageCount
    FROM UserBadges UB
    JOIN Posts P ON UB.UserId = P.OwnerUserId
    JOIN PostDetails PD ON P.Id = PD.PostId
    JOIN TagUsage T ON T.Tag = ANY(string_to_array(P.Tags, '>'))
    ORDER BY UB.TotalBadges DESC, PD.UpVotes DESC
)
SELECT DISTINCT *
FROM FinalReport
WHERE PopularTag IS NOT NULL
ORDER BY TotalBadges DESC, UpVotes DESC
LIMIT 20;
