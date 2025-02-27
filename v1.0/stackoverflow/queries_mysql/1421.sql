
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        (UpVotes - DownVotes) AS Score,
        RANK() OVER (ORDER BY (UpVotes - DownVotes) DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    T.DisplayName,
    T.Score,
    T.Rank,
    (SELECT GROUP_CONCAT(TT.TagName SEPARATOR ', ') 
     FROM Tags TT 
     WHERE TT.Id IN (SELECT DISTINCT CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '<>', n.n), '<>', -1) AS UNSIGNED) 
                     FROM (SELECT @row := @row + 1 AS n 
                           FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) t1, 
                                (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) t2, 
                                (SELECT @row := 0) t3) AS n 
                     WHERE n.n <= CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '<>', '')) + 1)
                    AND P.OwnerUserId IS NOT NULL
                    AND P.AnswerCount > 0) AS Tags
FROM 
    TopUsers T
JOIN 
    Posts P ON T.UserId = P.OwnerUserId
WHERE 
    T.Rank <= 10
AND 
    EXISTS (SELECT 1 FROM PostHistory PH 
            WHERE PH.PostId = P.Id 
            AND PH.PostHistoryTypeId IN (10, 12) 
            AND PH.CreationDate >= NOW() - INTERVAL 30 DAY)
ORDER BY 
    T.Score DESC
LIMIT 5 OFFSET 5;
