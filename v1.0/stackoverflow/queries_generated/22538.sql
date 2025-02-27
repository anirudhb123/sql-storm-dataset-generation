WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS TotalPosts
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserVoteStats AS (
    SELECT 
        V.UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes V
    GROUP BY 
        V.UserId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    COALESCE(UB.BadgeNames, 'No Badges') AS BadgeNames,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    COALESCE(UVS.UpVotes, 0) AS UserUpVotes,
    COALESCE(UVS.DownVotes, 0) AS UserDownVotes,
    RP.Rank,
    RP.TotalPosts,
    CASE 
        WHEN RP.Rank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostType,
    CASE 
        WHEN RP.ViewCount IS NULL THEN 'No Views Recorded'
        WHEN RP.ViewCount > 1000 THEN 'Highly Viewed'
        ELSE 'Regular Views'
    END AS ViewCountDescription
FROM 
    RankedPosts RP
LEFT JOIN 
    UserBadges UB ON RP.OwnerUserId = UB.UserId
LEFT JOIN 
    UserVoteStats UVS ON RP.OwnerUserId = UVS.UserId
WHERE 
    RP.Rank <= 5
ORDER BY 
    RP.CreationDate DESC
FETCH FIRST 10 ROWS ONLY;

WITH PotentialDuplicates AS (
    SELECT 
        P1.Id AS PostId1,
        P2.Id AS PostId2,
        P1.Title AS Title1,
        P2.Title AS Title2,
        PL.LinkTypeId
    FROM 
        Posts P1
    JOIN 
        PostLinks PL ON P1.Id = PL.PostId
    JOIN 
        Posts P2 ON PL.RelatedPostId = P2.Id
    WHERE 
        PL.LinkTypeId = 3 -- Considering duplicates
)
SELECT 
    *,
    CASE 
        WHEN PostId1 IS NOT NULL AND PostId2 IS NOT NULL THEN 'Possible Duplicate'
        ELSE 'Not a Duplicate'
    END AS DuplicateStatus
FROM 
    PotentialDuplicates;

-- A selection to demonstrate NULL logic and bizarre semantics:
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(B.BadgeNames, '[No Badges]') AS Badges,
    COALESCE(
        (SELECT AVG(Score) FROM Posts WHERE OwnerUserId = U.Id AND CreationDate > NOW() - INTERVAL '5 days'),
        0
    ) AS AvgScoreLast5Days,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Badges WHERE UserId = U.Id AND Class = 1) THEN 'Gold Member'
        ELSE 'Regular Member'
    END AS MembershipType
FROM 
    Users U
LEFT JOIN 
    (SELECT UserId, STRING_AGG(Name, ', ') AS BadgeNames FROM Badges GROUP BY UserId) B ON U.Id = B.UserId
WHERE 
    U.Reputation >= (SELECT AVG(Reputation) FROM Users) 
    OR (U.LastAccessDate IS NULL AND U.Views = 0)
ORDER BY 
    U.Reputation DESC
LIMIT 10;

