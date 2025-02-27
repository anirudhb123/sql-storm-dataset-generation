WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        SUM(CASE WHEN PH.UserId IS NOT NULL THEN 1 ELSE 0 END) AS EditsMade,
        COUNT(DISTINCT PH.Id) AS PostHistoryCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN PostHistory PH ON U.Id = PH.UserId
    GROUP BY U.Id, U.DisplayName
),
RankedUserActivity AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        CommentCount,
        TotalBounties,
        UpVotes,
        DownVotes,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        EditsMade,
        PostHistoryCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS PostRank,
        ROW_NUMBER() OVER (ORDER BY EditsMade DESC) AS EditRank
    FROM UserActivity
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    CommentCount,
    TotalBounties,
    UpVotes,
    DownVotes,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    EditsMade,
    PostHistoryCount,
    PostRank,
    EditRank
FROM RankedUserActivity
WHERE PostCount > 10 
  AND UpVotes > DownVotes
ORDER BY PostRank, EditRank;
