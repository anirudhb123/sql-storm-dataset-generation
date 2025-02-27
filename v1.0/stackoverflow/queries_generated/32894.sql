WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        Score,
        OwnerUserId,
        ParentId,
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.OwnerUserId,
        p.ParentId,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        MAX(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadge,
        MAX(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadge
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        U.DisplayName AS OwnerName,
        U.Reputation AS UserReputation,
        COALESCE(S.UpVotes, 0) AS UpVotes,
        COALESCE(S.DownVotes, 0) AS DownVotes,
        B.BadgeCount AS UserBadgeCount,
        B.GoldBadge,
        B.SilverBadge
    FROM 
        Posts p
    INNER JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        PostVoteSummary S ON p.Id = S.PostId
    LEFT JOIN 
        UserBadges B ON U.Id = B.UserId
),
RankedPosts AS (
    SELECT 
        P.*,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        PostActivity P
)
SELECT 
    PH.Id AS PostId,
    PH.Title,
    PH.Score,
    U.DisplayName AS OwnerName,
    U.Reputation,
    A.UpVotes,
    A.DownVotes,
    CASE 
        WHEN B.GoldBadge = 1 THEN 'Gold'
        WHEN B.SilverBadge = 1 THEN 'Silver'
        ELSE 'No Badge'
    END AS BadgeType,
    COALESCE(V.TotalVotes, 0) AS TotalVotes,
    PH.CreationDate,
    RANK() OVER (ORDER BY PH.Score DESC) AS OverallRank
FROM 
    RankedPosts PH
LEFT JOIN 
    Users U ON PH.OwnerUserId = U.Id
LEFT JOIN 
    PostVoteSummary V ON PH.Id = V.PostId
LEFT JOIN 
    UserBadges B ON U.Id = B.UserId
WHERE 
    PH.Score > 0
ORDER BY 
    OverallRank, Score DESC;
