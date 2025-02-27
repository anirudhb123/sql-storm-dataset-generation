WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, U.DisplayName
), UserBadges AS (
    SELECT 
        U.Id AS UserId,
        ARRAY_AGG(B.Name) AS BadgeNames,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgesCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgesCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgesCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.OwnerDisplayName,
    RP.CommentCount,
    RP.UpVotes,
    RP.DownVotes,
    UB.BadgeNames,
    COALESCE(UB.GoldBadgesCount, 0) AS GoldBadgesCount,
    COALESCE(UB.SilverBadgesCount, 0) AS SilverBadgesCount,
    COALESCE(UB.BronzeBadgesCount, 0) AS BronzeBadgesCount,
    CASE 
        WHEN RP.Rank = 1 THEN 'Most Recent Post'
        ELSE 'Subsequent Post'
    END AS PostRankDescription
FROM 
    RankedPosts RP
LEFT JOIN 
    UserBadges UB ON RP.OwnerDisplayName = UB.UserId
ORDER BY 
    RP.CommentCount DESC,
    RP.UpVotes DESC;
