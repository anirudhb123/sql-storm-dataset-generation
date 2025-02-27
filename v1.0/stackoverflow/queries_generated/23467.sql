WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate ASC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= (CURRENT_DATE - INTERVAL '30 days') 
        AND P.Score IS NOT NULL
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
Likes AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId IN (2, 5) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
PostHistoryWithComments AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.UserDisplayName,
        PH.CreationDate AS HistoryDate,
        COALESCE(C.Comment, 'No Comments') AS CommentText
    FROM 
        PostHistory PH
    LEFT JOIN 
        Comments C ON PH.PostId = C.PostId
    WHERE 
        PH.CreationDate >= (CURRENT_DATE - INTERVAL '90 days')
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    COALESCE(RP.Score, 0) AS PostScore,
    COALESCE(L.UpVotes, 0) AS TotalLikes,
    COALESCE(L.DownVotes, 0) AS TotalDislikes,
    UR.Reputation,
    UR.BadgeCount,
    PH.UserDisplayName AS EditedBy,
    PH.HistoryDate,
    PH.CommentText
FROM 
    RankedPosts RP
LEFT JOIN 
    Likes L ON RP.PostId = L.PostId
LEFT JOIN 
    UserReputation UR ON RP.OwnerUserId = UR.UserId
LEFT JOIN 
    PostHistoryWithComments PH ON RP.PostId = PH.PostId
WHERE 
    RP.PostRank <= 10 
    AND (UR.Reputation IS NOT NULL OR RP.OwnerUserId IS NULL)
ORDER BY 
    RP.Score DESC, 
    RP.CreationDate DESC;

-- This query combines various advanced SQL features including CTEs for organizing posts by rank,
-- join statistics from likes, user reputation, and related post history that includes comments, 
-- while handling corner cases with NULLs and ensuring comprehensive analysis.
