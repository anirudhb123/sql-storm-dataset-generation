
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(TIMESTAMPDIFF(SECOND, P.CreationDate, CURRENT_TIMESTAMP)) / 60 AS AvgPostAgeMinutes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    WHERE 
        U.Reputation >= 1000
    GROUP BY 
        U.Id, U.DisplayName
), 

TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        PositivePosts, 
        NegativePosts, 
        UpVotes, 
        DownVotes, 
        AvgPostAgeMinutes,
        @row_number := @row_number + 1 AS Rank
    FROM UserActivity, (SELECT @row_number := 0) AS rn
    ORDER BY PostCount DESC
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.PostCount,
    U.PositivePosts,
    U.NegativePosts,
    U.UpVotes,
    U.DownVotes,
    U.AvgPostAgeMinutes,
    RANK() OVER (ORDER BY U.PostCount DESC) AS OverallRank
FROM 
    TopUsers U
WHERE 
    U.Rank <= 10
ORDER BY 
    U.PostCount DESC;
