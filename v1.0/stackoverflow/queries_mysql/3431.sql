
WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotesCount,
        DownVotesCount,
        TotalPosts,
        TotalComments,
        @rownum := @rownum + 1 AS UserRank
    FROM 
        UserScores, (SELECT @rownum := 0) r
    ORDER BY 
        Reputation DESC, UpVotesCount DESC
)
SELECT 
    FU.DisplayName,
    FU.Reputation,
    FU.UpVotesCount,
    FU.DownVotesCount,
    FU.TotalPosts,
    FU.TotalComments,
    CASE 
        WHEN FU.Reputation >= 1000 THEN 'High Reputation'
        ELSE 'Moderate Reputation'
    END AS ReputationCategory,
    GROUP_CONCAT(DISTINCT T.TagName SEPARATOR ', ') AS TagList
FROM 
    FilteredUsers FU
LEFT JOIN 
    Posts P ON FU.UserId = P.OwnerUserId
LEFT JOIN 
    (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ',', numbers.n), ',', -1)) AS TagName
     FROM 
     (SELECT a.N + b.N * 10 + 1 n
      FROM 
      (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
      (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
      ORDER BY n) numbers
     WHERE numbers.n <= 1 + LENGTH(P.Tags) - LENGTH(REPLACE(P.Tags, ',', ''))) AS T ON true
GROUP BY 
    FU.UserId, FU.DisplayName, FU.Reputation, FU.UpVotesCount, FU.DownVotesCount, FU.TotalPosts, FU.TotalComments
ORDER BY 
    FU.Reputation DESC;
