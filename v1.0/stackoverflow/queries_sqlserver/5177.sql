
WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.ViewCount,
        P.Score,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVoteCount,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Posts A WHERE A.ParentId = P.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RowNum
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate > DATEADD(DAY, -30, '2024-10-01 12:34:56')
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.OwnerDisplayName,
    RP.ViewCount,
    RP.Score,
    RP.UpVoteCount,
    RP.DownVoteCount,
    RP.CommentCount,
    RP.AnswerCount
FROM 
    RecentPosts RP
WHERE 
    RP.RowNum = 1 
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
