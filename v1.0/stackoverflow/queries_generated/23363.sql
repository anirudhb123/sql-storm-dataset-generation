WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.OwnerUserId,
        COALESCE(PV.TotalVotes, 0) AS TotalVotes,
        (SELECT STRING_AGG(T.TagName, ', ') 
         FROM Tags T 
         WHERE T.Id IN (SELECT unnest(string_to_array(P.Tags, ','))::int)) AS TagsList,
        (SELECT COUNT(C.Id) 
         FROM Comments C 
         WHERE C.PostId = P.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN (SELECT PostId, COUNT(*) AS TotalVotes 
               FROM Votes 
               GROUP BY PostId) PV ON P.Id = PV.PostId
)
SELECT 
    UD.DisplayName,
    UD.BadgeCount,
    UD.GoldCount,
    UD.SilverCount,
    UD.BronzeCount,
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.ViewCount,
    PD.Score,
    PD.TotalVotes,
    PD.TagsList,
    PD.CommentCount,
    COALESCE(PH.Comment, 'No comments') AS LastPostAction
FROM UserBadges UD
JOIN PostDetails PD ON PD.OwnerUserId = UD.UserId
LEFT JOIN (
    SELECT 
        PostId, 
        MAX(CreationDate) AS LastActionDate,
        MAX(Comment) AS Comment
    FROM PostHistory
    WHERE PostHistoryTypeId IN (10, 11, 12)  -- Considering only post close, reopen, delete actions
    GROUP BY PostId
) PH ON PD.PostId = PH.PostId
WHERE UD.BadgeCount > 5 
AND PD.ViewCount > 100 
AND PD.CreationDate < NOW() - INTERVAL '1 year'
ORDER BY UD.BadgeCount DESC, PD.Score DESC
LIMIT 50;
