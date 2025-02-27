WITH UserScoreSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id, U.DisplayName
),
MostActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount,
        TotalScore,
        RANK() OVER (ORDER BY PostCount DESC) AS ActivityRank
    FROM 
        UserScoreSummary
    WHERE 
        PostCount > 5
),
TopVotedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.ViewCount, U.DisplayName
    HAVING 
        COUNT(V.Id) > 10
    ORDER BY 
        TotalUpVotes DESC
    LIMIT 10
)
SELECT 
    A.DisplayName AS ActiveUser,
    A.PostCount,
    A.TotalScore,
    T.Title AS TopPostTitle,
    T.ViewCount,
    T.TotalUpVotes,
    T.TotalDownVotes,
    T.OwnerDisplayName
FROM 
    MostActiveUsers A
JOIN 
    TopVotedPosts T ON A.UserId = T.OwnerDisplayName
ORDER BY 
    A.ActivityRank, T.TotalUpVotes DESC
LIMIT 20;
