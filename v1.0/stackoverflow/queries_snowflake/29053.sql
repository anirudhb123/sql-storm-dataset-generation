
WITH PostTagCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(T.TagName) AS TagCount,
        LISTAGG(T.TagName, ', ') WITHIN GROUP (ORDER BY T.TagName) AS AllTags
    FROM Posts P
    LEFT JOIN Tags T ON POSITION(T.TagName IN P.Tags) > 0
    WHERE P.PostTypeId = 1 
    GROUP BY P.Id
), 
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        LISTAGG(B.Name, ', ') WITHIN GROUP (ORDER BY B.Name) AS BadgeList
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
), 
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        tags.TagCount,
        tags.AllTags,
        badges.BadgeCount,
        badges.BadgeList,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        LISTAGG(CONCAT('VoterId: ', V.UserId, ' VoteType: ', VT.Name), '; ') WITHIN GROUP (ORDER BY V.UserId) AS VoteDetails
    FROM Posts P
    LEFT JOIN PostTagCounts tags ON P.Id = tags.PostId
    LEFT JOIN UserBadges badges ON P.OwnerUserId = badges.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN VoteTypes VT ON V.VoteTypeId = VT.Id
    WHERE P.CreationDate >= DATEADD(day, -30, '2024-10-01')
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, tags.TagCount, tags.AllTags, badges.BadgeCount, badges.BadgeList
)
SELECT 
    PA.PostId,
    PA.Title,
    PA.CreationDate,
    PA.ViewCount,
    PA.Score,
    PA.TagCount,
    PA.AllTags,
    PA.BadgeCount,
    PA.BadgeList,
    PA.CommentCount,
    PA.VoteDetails
FROM PostAnalytics PA
ORDER BY PA.Score DESC, PA.ViewCount DESC
LIMIT 100;
