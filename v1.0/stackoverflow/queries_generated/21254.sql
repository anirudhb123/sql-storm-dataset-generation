WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount, 
        P.AcceptedAnswerId,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVotes
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.ViewCount, P.AcceptedAnswerId
),
TagStatistics AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore,
        COUNT(CASE WHEN P.CreationDate > CURRENT_DATE - INTERVAL '30 days' THEN 1 END) AS RecentPosts
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.Id, T.TagName
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UB.BadgeCount,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    P.Title AS PostTitle,
    P.ViewCount,
    P.CommentCount,
    P.UpVotes,
    P.DownVotes,
    CASE 
        WHEN P.AcceptedAnswerId IS NOT NULL THEN 
            (SELECT COUNT(*) FROM Posts A WHERE A.Id = P.AcceptedAnswerId AND A.AnswerCount > 0)
        ELSE 0 
    END AS AcceptedAnswerCount,
    T.TagName,
    T.PostCount,
    T.AverageScore,
    T.RecentPosts
FROM Users U
JOIN UserBadges UB ON U.Id = UB.UserId
LEFT JOIN PostDetails P ON U.Id = P.OwnerUserId
LEFT JOIN TagStatistics T ON P.Tags LIKE CONCAT('%', T.TagName, '%')
WHERE 
    U.Reputation > 100 
    AND (P.ViewCount IS NULL OR P.ViewCount > 50) 
    AND (P.CommentCount IS NOT NULL OR P.UpVotes IS NOT NULL)
    AND (T.PostCount > 0 OR (T.PostCount IS NULL AND P.CommentCount > 0))
ORDER BY 
    UB.BadgeCount DESC,
    P.ViewCount DESC,
    T.AverageScore DESC
LIMIT 100;

