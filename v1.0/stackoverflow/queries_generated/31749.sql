WITH RecursivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT 
        A.Id,
        A.Title,
        A.Score,
        A.ViewCount,
        A.CreationDate,
        A.AcceptedAnswerId,
        RP.Level + 1
    FROM 
        Posts A
    INNER JOIN RecursivePosts RP ON A.ParentId = RP.PostId
    WHERE 
        A.PostTypeId = 2 -- Answers
),
BadgedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
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
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.ViewCount,
        RP.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation,
        COALESCE(SUM(CASE WHEN C.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalComments,
        COALESCE(V.UpVotes, 0) AS UpVotes,
        COALESCE(V.DownVotes, 0) AS DownVotes
    FROM 
        RecursivePosts RP
    LEFT JOIN 
        Users U ON RP.OwnerUserId = U.Id 
    LEFT JOIN 
        Comments C ON RP.PostId = C.PostId
    LEFT JOIN 
        (SELECT 
            UserId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM Votes
         GROUP BY UserId) V ON U.Id = V.UserId
    GROUP BY 
        RP.PostId, RP.Title, RP.Score, RP.ViewCount, RP.CreationDate, U.DisplayName, U.Reputation
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.Score,
    PD.ViewCount,
    PD.CreationDate,
    PD.OwnerDisplayName,
    PD.OwnerReputation,
    BD.TotalBadges,
    BD.GoldBadges,
    BD.SilverBadges,
    BD.BronzeBadges,
    PD.TotalComments,
    COALESCE(PH.CloseReason, 'Not Closed') AS CloseReason
FROM 
    PostDetails PD
LEFT JOIN 
    (SELECT 
         Ph.PostId,
         CT.Name AS CloseReason
     FROM 
         PostHistory Ph
     JOIN 
         CloseReasonTypes CT ON Ph.Comment::integer = CT.Id
     WHERE 
         Ph.PostHistoryTypeId = 10 -- Post Closed
    ) PH ON PD.PostId = PH.PostId
JOIN 
    BadgedUsers BD ON PD.OwnerDisplayName = BD.DisplayName
ORDER BY 
    PD.Score DESC, PD.ViewCount DESC
LIMIT 100;
