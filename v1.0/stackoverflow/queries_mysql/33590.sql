
WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        1 AS Level
    FROM Users U
    WHERE U.Reputation > 10000  
    UNION ALL
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        UR.Level + 1
    FROM Users U
    JOIN UserReputation UR ON U.Reputation > UR.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
        COUNT(CASE WHEN Ph.Comment IS NOT NULL THEN 1 END) AS EditCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory Ph ON P.Id = Ph.PostId
    GROUP BY P.Id, P.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        PS.PostId,
        PS.OwnerUserId,
        PS.TotalBounty,
        PS.CommentCount,
        PS.VoteCount,
        PS.EditCount,
        U.Reputation AS OwnerReputation
    FROM PostStats PS
    JOIN Users U ON PS.OwnerUserId = U.Id
    WHERE PS.CommentCount > 5 AND PS.VoteCount > 10
),
RankedPosts AS (
    SELECT 
        FP.PostId,
        FP.OwnerUserId,
        FP.TotalBounty,
        FP.CommentCount,
        FP.VoteCount,
        FP.EditCount,
        FP.OwnerReputation,
        @rank := IF(@prevOwnerUserId = FP.OwnerUserId, @rank + 1, 1) AS Rank,
        @prevOwnerUserId := FP.OwnerUserId
    FROM FilteredPosts FP, (SELECT @rank := 0, @prevOwnerUserId := NULL) r
    ORDER BY FP.OwnerUserId, FP.VoteCount DESC, FP.CommentCount DESC
)
SELECT 
    RP.PostId,
    U.DisplayName AS OwnerName,
    RP.TotalBounty,
    RP.CommentCount,
    RP.VoteCount,
    RP.EditCount,
    RP.Rank,
    COALESCE(T.TagName, 'No Tag') AS TopTag
FROM RankedPosts RP
JOIN Users U ON RP.OwnerUserId = U.Id
LEFT JOIN (
    SELECT 
        TL.PostId,
        T.TagName,
        @tag_rank := IF(@tag_prevPostId = TL.PostId, @tag_rank + 1, 1) AS TagRank,
        @tag_prevPostId := TL.PostId
    FROM PostLinks TL, (SELECT @tag_rank := 0, @tag_prevPostId := NULL) tr
    JOIN Tags T ON TL.RelatedPostId = T.Id
    ORDER BY TL.PostId, T.Count DESC
) T ON RP.PostId = T.PostId AND T.TagRank = 1
WHERE RP.Rank = 1  
ORDER BY RP.OwnerReputation DESC, RP.CommentCount DESC;
