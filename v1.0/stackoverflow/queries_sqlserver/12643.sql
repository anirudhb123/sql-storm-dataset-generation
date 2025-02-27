
WITH PostStats AS (
    SELECT 
        P.PostTypeId,
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AverageViewCount,
        AVG(Score) AS AverageScore,
        AVG(AnswerCount) AS AverageAnswerCount,
        AVG(CommentCount) AS AverageCommentCount
    FROM Posts P
    WHERE P.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY P.PostTypeId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS TotalBadges,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes,
        AVG(U.Reputation) AS AverageReputation
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
)
SELECT 
    PST.PostTypeId,
    PST.TotalPosts,
    PST.AverageViewCount,
    PST.AverageScore,
    PST.AverageAnswerCount,
    PST.AverageCommentCount,
    US.TotalBadges,
    US.TotalUpVotes,
    US.TotalDownVotes,
    US.AverageReputation
FROM PostStats PST
JOIN UserStats US ON US.UserId = (SELECT TOP 1 Id FROM Users ORDER BY Id ASC)  
ORDER BY PST.PostTypeId;
