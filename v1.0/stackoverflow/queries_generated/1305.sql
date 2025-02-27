WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(U.DisplayName, 'Community User') AS OwnerDisplayName,
        (
            SELECT COUNT(C.Id)
            FROM Comments C
            WHERE C.PostId = P.Id
        ) AS CommentCount,
        (
            SELECT COUNT(A.Id)
            FROM Posts A
            WHERE A.ParentId = P.Id AND A.PostTypeId = 2
        ) AS AnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.AnswerCount,
    UVC.DisplayName AS TopVoter,
    UVC.TotalVotes AS TopVotes,
    (ROW_NUMBER() OVER (PARTITION BY PS.PostId ORDER BY UVC.TotalVotes DESC)) AS Rank
FROM 
    PostStats PS
JOIN 
    UserVoteCounts UVC ON UVC.UserId IN (
        SELECT UserId 
        FROM Votes 
        WHERE PostId = PS.PostId
    )
WHERE 
    PS.Score > 5
ORDER BY 
    PS.ViewCount DESC, PS.Score DESC
LIMIT 10;
