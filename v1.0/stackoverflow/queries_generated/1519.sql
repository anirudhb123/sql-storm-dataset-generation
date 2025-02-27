WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) DESC) AS UserRank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 AND
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.OwnerUserId
),
AggregateVotes AS (
    SELECT 
        PostId,
        SUM(UpvoteCount) AS TotalUpvotes,
        SUM(DownvoteCount) AS TotalDownvotes
    FROM 
        (SELECT PostId, UpvoteCount, DownvoteCount FROM RankedPosts) AS Sub
    GROUP BY 
        PostId
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(B.Class = 1) AS GoldBadges,
        SUM(B.Class = 2) AS SilverBadges,
        SUM(B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    AU.DisplayName,
    AU.TotalPosts,
    AU.GoldBadges,
    AU.SilverBadges,
    AU.BronzeBadges,
    COALESCE(AVG(AV.TotalUpvotes - AV.TotalDownvotes), 0) AS NetVotes
FROM 
    ActiveUsers AU
LEFT JOIN 
    AggregateVotes AV ON AU.UserId = AV.PostId
WHERE 
    AU.TotalPosts > 5
GROUP BY 
    AU.DisplayName, AU.TotalPosts, AU.GoldBadges, AU.SilverBadges, AU.BronzeBadges
ORDER BY 
    NetVotes DESC
LIMIT 10;
