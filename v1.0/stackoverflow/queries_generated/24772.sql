WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') FILTER (WHERE B.Class = 1) AS GoldBadges,
        STRING_AGG(B.Name, ', ') FILTER (WHERE B.Class = 2) AS SilverBadges,
        STRING_AGG(B.Name, ', ') FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        CASE 
            WHEN P.PostTypeId = 1 THEN (SELECT COUNT(*) FROM Posts A WHERE A.ParentId = P.Id AND A.PostTypeId = 2 AND A.Deleted = 0)
            ELSE 0
        END AS AnswerCount,
        CASE 
            WHEN P.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM Posts P
),
VoteCount AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
),
TagDetails AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        STRING_AGG(P.Title, '; ') AS PostTitles
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
)
SELECT 
    U.DisplayName,
    UP.BadgeCount,
    UP.GoldBadges,
    UP.SilverBadges,
    UP.BronzeBadges,
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.Score,
    PD.ViewCount,
    PD.AnswerCount,
    PD.PostStatus,
    VC.TotalVotes,
    VC.UpVotes,
    VC.DownVotes,
    TG.TagName,
    TG.PostCount,
    TG.PostTitles
FROM UserBadges UP
JOIN Users U ON UP.UserId = U.Id
LEFT JOIN PostDetails PD ON U.Id = PD.OwnerUserId
LEFT JOIN VoteCount VC ON PD.PostId = VC.PostId
LEFT JOIN TagDetails TG ON PD.Title LIKE '%' || TG.TagName || '%'
WHERE (UP.BadgeCount > 0 OR PD.PostStatus = 'Closed')
  AND (PD.ViewCount IS NOT NULL AND PD.ViewCount > 0)
  AND (TG.PostCount IS NULL OR TG.PostCount < 5)
ORDER BY PD.CreationDate DESC NULLS LAST
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
