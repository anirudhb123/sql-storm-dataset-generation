
WITH UserVotes AS (
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
        P.CreationDate,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(V.TotalVotes, 0) AS TotalVotes,
        COALESCE(V.UpVotes, 0) AS UpVotes,
        COALESCE(V.DownVotes, 0) AS DownVotes,
        @row_number := @row_number + 1 AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        UserVotes V ON P.OwnerUserId = V.UserId, (SELECT @row_number := 0) AS rn
    WHERE 
        P.CreationDate >= CURDATE() - INTERVAL 1 YEAR
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.AnswerCount,
    PS.TotalVotes,
    PS.UpVotes,
    PS.DownVotes,
    CASE 
        WHEN PS.PostRank <= 10 THEN 'Top Post'
        WHEN PS.TotalVotes = 0 THEN 'No Votes'
        ELSE 'Average Post'
    END AS PostCategory
FROM 
    PostStats PS
WHERE 
    PS.AnswerCount > 0
ORDER BY 
    PS.TotalVotes DESC, PS.CreationDate ASC
LIMIT 100;
