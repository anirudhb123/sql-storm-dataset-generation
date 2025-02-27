
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.CreationDate <= TIMESTAMP('2024-10-01 12:34:56') - INTERVAL 1 YEAR
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        CommentCount, 
        UpVotes, 
        DownVotes,
        @row_number := @row_number + 1 AS Rank
    FROM 
        UserStats, (SELECT @row_number := 0) AS rn
    ORDER BY 
        Reputation DESC
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    T.CommentCount,
    T.UpVotes,
    T.DownVotes,
    T.Rank,
    GROUP_CONCAT(DISTINCT TAG.TagName) AS ExpertiseTags
FROM 
    TopUsers T
LEFT JOIN 
    Posts P ON T.UserId = P.OwnerUserId
LEFT JOIN 
    (SELECT P.OwnerUserId, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '<>', n.n), '<>', -1)) AS TagName
     FROM Posts P 
     JOIN (SELECT a.N + b.N * 10 + 1 n FROM 
           (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a, 
           (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b 
           ORDER BY n) n 
     WHERE n.n <= 1 + (LENGTH(P.Tags) - LENGTH(REPLACE(P.Tags, '<>', ''))) 
     ORDER BY P.OwnerUserId, n.n) AS TAG ON P.OwnerUserId = TAG.OwnerUserId
WHERE 
    T.Rank <= 10
GROUP BY 
    T.UserId, T.DisplayName, T.Reputation, T.PostCount, T.CommentCount, T.UpVotes, T.DownVotes, T.Rank
ORDER BY 
    T.Rank;
