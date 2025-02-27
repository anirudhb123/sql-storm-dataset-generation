WITH RecursiveUserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(V.Amount, 0)) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(COALESCE(V.BountyAmount, 0)) DESC) AS BountyRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty 
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
),
TopPosts AS (
    SELECT 
        ST.PostId,
        ST.Title,
        ST.CreationDate,
        ST.Score,
        ST.ViewCount,
        ST.CommentCount,
        ST.VoteCount,
        ST.TotalBounty,
        RANK() OVER (ORDER BY ST.Score DESC, ST.ViewCount DESC) AS Rank
    FROM 
        PostStatistics ST
    WHERE 
        ST.Score > 0
)
SELECT 
    UA.UserId, 
    UA.DisplayName, 
    UA.Reputation,
    TP.Title AS TopPostTitle,
    TP.CreationDate AS PostCreationDate,
    TP.Score AS PostScore,
    TP.ViewCount AS PostViewCount,
    TP.CommentCount AS PostCommentCount,
    TP.VoteCount AS PostVoteCount,
    TP.TotalBounty AS PostTotalBounty
FROM 
    RecursiveUserActivity UA
LEFT JOIN 
    TopPosts TP ON UA.PostCount > 5 AND UA.UserId = TP.PostId
WHERE 
    UA.BountyRank <= 5 
ORDER BY 
    UA.Reputation DESC, 
    TP.Score DESC;
