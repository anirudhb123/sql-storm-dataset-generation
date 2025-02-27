WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId, 
        P.Title AS PostTitle, 
        P.ParentId,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL  -- Start with top-level questions

    UNION ALL

    SELECT 
        P.Id AS PostId, 
        P.Title AS PostTitle, 
        P.ParentId,
        Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy RPH ON P.ParentId = RPH.PostId  -- Recursive join for answers
),
UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    WHERE 
        U.Reputation > 0
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
TopBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    WHERE 
        B.Class = 1  -- Only Gold badges
    GROUP BY 
        B.UserId
),
PostsWithSummary AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(PVS.UpVotes, 0) AS UpVotes,
        COALESCE(PVS.DownVotes, 0) AS DownVotes,
        COALESCE(PVS.TotalVotes, 0) AS TotalVotes,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation,
        TB.BadgeNames
    FROM 
        Posts P
    LEFT JOIN 
        PostVoteSummary PVS ON P.Id = PVS.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        TopBadges TB ON U.Id = TB.UserId
)

SELECT 
    RPH.PostId,
    RPH.PostTitle,
    RPH.Level,
    PWS.Title AS RelatedPostTitle,
    PWS.ViewCount AS RelatedViewCount,
    PWS.UpVotes AS RelatedUpVotes,
    PWS.DownVotes AS RelatedDownVotes,
    PWS.TotalVotes AS RelatedTotalVotes,
    PWS.OwnerDisplayName,
    PWS.OwnerReputation,
    PWS.BadgeNames
FROM 
    RecursivePostHierarchy RPH
LEFT JOIN 
    PostsWithSummary PWS ON RPH.PostId = PWS.Id
WHERE 
    RPH.Level = 0  -- Examining only top-level questions
ORDER BY 
    RPH.PostId
OPTION (MAXRECURSION 100);
