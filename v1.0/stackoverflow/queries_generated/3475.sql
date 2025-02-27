WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT V.Id) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '30 days' -- Posts created in the last 30 days
    GROUP BY 
        P.Id, P.OwnerUserId
),
RankedPosts AS (
    SELECT 
        PS.PostId,
        PS.OwnerUserId,
        PS.CommentCount,
        PS.UpVotes,
        PS.DownVotes,
        PS.TotalVotes,
        RANK() OVER (PARTITION BY PS.OwnerUserId ORDER BY PS.TotalVotes DESC) AS VoteRank
    FROM 
        PostStats PS
)
SELECT 
    UB.UserId,
    U.DisplayName,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    RP.PostId,
    RP.CommentCount,
    RP.UpVotes,
    RP.DownVotes,
    RP.TotalVotes,
    RP.VoteRank
FROM 
    UserBadges UB
JOIN 
    RankedPosts RP ON UB.UserId = RP.OwnerUserId
WHERE 
    RP.VoteRank <= 5 -- Get top 5 posts by votes per user
ORDER BY 
    UB.UserId, RP.VoteRank;
