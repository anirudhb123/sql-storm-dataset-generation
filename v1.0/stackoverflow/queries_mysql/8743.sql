
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS Author,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= '2023-01-01'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        Author
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
),
PostCommentStats AS (
    SELECT 
        PostId,
        COUNT(C.Id) AS CommentCount
    FROM 
        Comments C
    GROUP BY 
        PostId
),
PostVoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        PostId
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.Score,
    TP.ViewCount,
    TP.Author,
    COALESCE(PCS.CommentCount, 0) AS CommentCount,
    COALESCE(PVS.UpVotes, 0) AS UpVotes,
    COALESCE(PVS.DownVotes, 0) AS DownVotes
FROM 
    TopPosts TP
LEFT JOIN 
    PostCommentStats PCS ON TP.PostId = PCS.PostId
LEFT JOIN 
    PostVoteStats PVS ON TP.PostId = PVS.PostId
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;
