WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        PostId
),
TaggedPostInfo AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        array_agg(T.TagName) AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        unnest(string_to_array(P.Tags, '><')) AS TagName ON T.TagName = TagName
    GROUP BY 
        P.Id, P.Title
),
TopPostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.CreationDate,
        PO.TotalVotes,
        UBC.BadgeCount AS UserBadgeCount,
        UBC.GoldBadges,
        UBC.SilverBadges,
        UBC.BronzeBadges,
        TPI.Tags
    FROM 
        Posts P
    JOIN 
        PostVoteCounts PO ON P.Id = PO.PostId
    LEFT JOIN 
        UserBadgeCounts UBC ON UBC.UserId = P.OwnerUserId
    LEFT JOIN 
        TaggedPostInfo TPI ON TPI.PostId = P.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year' -- filter recent posts
)

SELECT 
    TPS.PostId,
    TPS.Title,
    TPS.CreationDate,
    TPS.TotalVotes,
    TPS.UserBadgeCount,
    CASE 
        WHEN TPS.TotalVotes > 10 THEN 'Highly Voted'
        WHEN TPS.TotalVotes BETWEEN 5 AND 10 THEN 'Moderately Voted'
        ELSE 'Less Voted'
    END AS VoteCategory,
    COALESCE(TPS.Tags, '{}') AS TagsList,
    (SELECT COUNT(*)
     FROM Posts P2
     WHERE P2.OwnerUserId = TPS.OwnerUserId AND P2.Id <> TPS.PostId) AS OtherPostsByUser,
    CASE 
        WHEN TPS.GoldBadges > 0 THEN 'Gold Badges Achieved!'
        ELSE NULL 
    END AS BadgeAchievement
FROM 
    TopPostStats TPS
WHERE 
    TPS.UserBadgeCount IS NOT NULL AND 
    (TPS.TotalVotes > 0 OR TPS.UserBadgeCount > 0)
ORDER BY 
    TPS.TotalVotes DESC, TPS.CreationDate ASC
LIMIT 50;
