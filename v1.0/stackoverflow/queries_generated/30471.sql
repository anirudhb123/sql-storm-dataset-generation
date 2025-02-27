WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Start with Questions
    UNION ALL
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        R.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy R ON P.ParentId = R.PostId
),
PostVoteSummary AS (
    SELECT
        P.Id AS PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
UserBadgeCounts AS (
    SELECT
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    PH.PostId,
    PH.Title,
    PH.Level,
    PV.UpVotes,
    PV.DownVotes,
    PV.TotalVotes,
    COALESCE(UBC.UserId, -1) AS UserId,
    COALESCE(UBC.GoldBadges, 0) AS GoldBadges,
    COALESCE(UBC.SilverBadges, 0) AS SilverBadges,
    COALESCE(UBC.BronzeBadges, 0) AS BronzeBadges
FROM 
    RecursivePostHierarchy PH
LEFT JOIN 
    PostVoteSummary PV ON PH.PostId = PV.PostId
LEFT JOIN 
    Users U ON U.Id = PH.PostId  -- Assuming users own the posts for simplicity
LEFT JOIN 
    UserBadgeCounts UBC ON U.Id = UBC.UserId
WHERE 
    PH.Level <= 3  -- Limiting to 3 levels deep for hierarchy
ORDER BY 
    PH.Level, PV.TotalVotes DESC;

