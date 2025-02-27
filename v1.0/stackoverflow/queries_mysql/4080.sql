
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostAnswerCounts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS AnswerCount
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 2 
    GROUP BY 
        P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(UAC.UpVotes, 0) AS UpVotes,
        COALESCE(UAC.DownVotes, 0) AS DownVotes,
        COALESCE(PAC.AnswerCount, 0) AS Answers,
        U.Reputation,
        @row_number := @row_number + 1 AS Rank
    FROM 
        Users U
    LEFT JOIN 
        UserVoteCounts UAC ON U.Id = UAC.UserId
    LEFT JOIN 
        PostAnswerCounts PAC ON U.Id = PAC.OwnerUserId,
        (SELECT @row_number := 0) AS rn
    ORDER BY 
        COALESCE(UAC.UpVotes, 0) DESC, U.Reputation DESC
)
SELECT 
    TU.DisplayName,
    TU.UpVotes,
    TU.DownVotes,
    TU.Answers,
    TU.Reputation,
    CASE 
        WHEN TU.Rank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType
FROM 
    TopUsers TU
WHERE 
    TU.Reputation > 100
ORDER BY 
    TU.UpVotes DESC, 
    TU.Answers DESC;
