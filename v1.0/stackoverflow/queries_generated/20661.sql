WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentPosts AS (
    SELECT 
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        P.OwnerUserId, P.Title, P.CreationDate, P.AcceptedAnswerId
),
UserStats AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        UR.BadgeCount,
        RP.Title AS RecentPostTitle,
        RP.CreationDate AS RecentPostDate,
        RP.UpVotes,
        RP.DownVotes
    FROM 
        UserReputation UR
    LEFT JOIN 
        RecentPosts RP ON UR.UserId = RP.OwnerUserId
)
SELECT 
    US.DisplayName,
    US.Reputation,
    US.BadgeCount,
    COALESCE(US.RecentPostTitle, 'No recent posts') AS RecentPostTitle,
    COALESCE(US.RecentPostDate, 'N/A') AS RecentPostDate,
    COALESCE(US.UpVotes, 0) AS UpVotes,
    COALESCE(US.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN US.BadgeCount > 10 THEN 'Veteran User' 
        ELSE 'Newbie'
    END AS UserType
FROM 
    UserStats US
RIGHT JOIN 
    Users U ON US.UserId = U.Id
WHERE 
    U.Reputation > 100
ORDER BY 
    US.Reputation DESC NULLS LAST
LIMIT 50;
