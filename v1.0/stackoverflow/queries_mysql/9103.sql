
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        P.CreationDate,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId IN (1, 2) 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.OwnerUserId, U.DisplayName
),
RankedPosts AS (
    SELECT 
        PS.*, 
        @rank := IF(@prev_vote_count = PS.VoteCount AND @prev_comment_count = PS.CommentCount, @rank, @rank + 1) AS Rank,
        @prev_vote_count := PS.VoteCount,
        @prev_comment_count := PS.CommentCount
    FROM 
        PostStats PS, (SELECT @rank := 0, @prev_vote_count := NULL, @prev_comment_count := NULL) r
    ORDER BY 
        PS.VoteCount DESC, PS.CommentCount DESC
)
SELECT 
    RP.Rank,
    RP.Title,
    RP.CommentCount,
    RP.UpVoteCount,
    RP.DownVoteCount,
    RP.CreationDate,
    RP.OwnerDisplayName
FROM 
    RankedPosts RP
WHERE 
    RP.Rank <= 10 
ORDER BY 
    RP.Rank;
