
WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(COALESCE(P.Score, 0)) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id AND P.OwnerUserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        PostCount,
        AvgScore,
        @rankByUpVotes := IF(@prevUpVotes = UpVotes, @rankByUpVotes, @rankByUpVotes + 1) AS RankByUpVotes,
        @prevUpVotes := UpVotes,
        @rankByDownVotes := IF(@prevDownVotes = DownVotes, @rankByDownVotes, @rankByDownVotes + 1) AS RankByDownVotes,
        @prevDownVotes := DownVotes
    FROM 
        UserVoteSummary, (SELECT @rankByUpVotes := 0, @prevUpVotes := NULL, @rankByDownVotes := 0, @prevDownVotes := NULL) AS vars
    ORDER BY UpVotes DESC, DownVotes DESC
)
SELECT 
    A.UserId,
    A.DisplayName,
    A.UpVotes,
    A.DownVotes,
    A.PostCount,
    A.AvgScore,
    B.RankByUpVotes,
    B.RankByDownVotes
FROM 
    UserVoteSummary A
JOIN 
    TopUsers B ON A.UserId = B.UserId
WHERE 
    (A.UpVotes > (SELECT AVG(UpVotes) FROM UserVoteSummary) OR 
    A.DownVotes < (SELECT AVG(DownVotes) / 2 FROM UserVoteSummary))
ORDER BY 
    A.UpVotes DESC, A.DownVotes ASC
LIMIT 10;
