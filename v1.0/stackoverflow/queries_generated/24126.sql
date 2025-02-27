WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 100 -- Focus on users with substantial reputation
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        DisplayName,
        PostCount,
        CommentCount,
        UpVotes,
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserReputation
)
SELECT 
    RU.UserRank,
    RU.DisplayName,
    RU.PostCount,
    RU.CommentCount,
    COALESCE(NULLIF(RU.UpVotes, 0), 1) AS EffectiveUpVotes, -- Avoid zero divide
    COALESCE(NULLIF(RU.DownVotes, 0), 1) AS EffectiveDownVotes,
    CASE 
        WHEN RU.UpVotes > RU.DownVotes THEN 'Positive Influencer'
        WHEN RU.UpVotes < RU.DownVotes THEN 'Negative Influencer'
        ELSE 'Balanced User'
    END AS InfluenceType,
    STDEV(RU.Reputation) OVER () AS StdDevReputation -- Measure reputation variance
FROM 
    TopUsers RU
WHERE 
    RU.UserRank <= 10 -- Top 10 users 
ORDER BY 
    RU.UserRank;

-- Additional queries or constructs for performance benchmarking
WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS TotalUpVotes,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS TotalDownVotes,
        CASE
            WHEN (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id) = 0 THEN 'No Votes'
            ELSE 
                CASE 
                    WHEN (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) > 
                         (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) 
                    THEN 'More UpVotes'
                    ELSE 'More DownVotes'
                END 
        END AS VotingTrend
    FROM 
        Posts P
    WHERE 
        P.CreationDate > NOW() - INTERVAL '1 year' -- Filter for recent posts
)
SELECT 
    P.*,
    PS.TotalUpVotes,
    PS.TotalDownVotes,
    PS.VotingTrend
FROM 
    Posts P
LEFT JOIN 
    PostStatistics PS ON P.Id = PS.PostId
WHERE 
    P.Score > (SELECT AVG(Score) FROM Posts) -- Above average score
ORDER BY 
    PS.TotalUpVotes DESC, P.CreationDate DESC;
