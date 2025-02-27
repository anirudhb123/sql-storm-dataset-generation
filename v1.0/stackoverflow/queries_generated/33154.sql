WITH RecursivePostHierarchy AS (
    SELECT 
        Id, 
        Title, 
        ParentId, 
        0 AS Level 
    FROM 
        Posts 
    WHERE 
        ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id, 
        p.Title, 
        p.ParentId,
        Level + 1 
    FROM 
        Posts p 
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostVotes AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P 
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U 
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    R.Id AS PostId,
    R.Title AS PostTitle,
    COALESCE(V.TotalVotes, 0) AS TotalVotes,
    COALESCE(V.UpVotes, 0) AS UpVotes,
    COALESCE(V.DownVotes, 0) AS DownVotes,
    U.Id AS UserId,
    U.DisplayName AS UserName,
    UB.BadgeCount AS TotalBadges,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    R.Level AS PostLevel,
    STRING_AGG(T.TagName, ', ') AS Tags
FROM 
    RecursivePostHierarchy R
LEFT JOIN 
    PostVotes V ON R.Id = V.PostId
LEFT JOIN 
    Posts P ON R.Id = P.Id
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    Tags T ON T.ExcerptPostId = P.Id
GROUP BY 
    R.Id, R.Title, V.TotalVotes, V.UpVotes, V.DownVotes, U.Id, U.DisplayName, UB.BadgeCount, UB.GoldBadges, UB.SilverBadges, UB.BronzeBadges, R.Level
ORDER BY 
    R.Level, TotalVotes DESC;
