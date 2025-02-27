WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(CASE WHEN V.VoteTypeId = 5 THEN 1 END) AS Favorites,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (8, 9) THEN V.BountyAmount ELSE 0 END), 0) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.AnswerCount,
        IIF(P.ClosedDate IS NOT NULL, 'Closed', 'Open') AS PostStatus,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.ViewCount > 100
),
RankedPosts AS (
    SELECT 
        PS.*,
        UV.UserId,
        UV.DisplayName AS OwnerName,
        UV.Upvotes,
        UV.Downvotes,
        UV.Favorites,
        UV.TotalBounties
    FROM 
        PostStats PS
    JOIN 
        Users U ON PS.OwnerUserId = U.Id
    LEFT JOIN 
        UserVoteStats UV ON PS.OwnerUserId = UV.UserId
)
SELECT 
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.PostStatus,
    RP.Rank,
    RP.OwnerName,
    RP.Upvotes,
    RP.Downvotes,
    RP.Favorites,
    RP.TotalBounties
FROM 
    RankedPosts RP
WHERE 
    RP.Rank <= 5
ORDER BY 
    RP.Score DESC, RP.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

WITH RecentActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        C.CreationDate AS CommentDate,
        C.Text AS CommentText,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY C.CreationDate DESC) AS CommentRank
    FROM 
        Posts P
    JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        C.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 month'
)
SELECT 
    R.PostId,
    R.Title,
    R.CommentDate,
    R.CommentText
FROM 
    RecentActivity R
WHERE 
    R.CommentRank = 1
ORDER BY 
    R.CommentDate DESC;
