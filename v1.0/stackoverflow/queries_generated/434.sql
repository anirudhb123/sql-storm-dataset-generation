WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(B.Class, 0)) AS TotalBadges,
        ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(P.Score, 0)) DESC) AS Rank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3), 0) AS DownVotes
    FROM Posts P
),
RankingPost AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.ViewCount,
        PD.AnswerCount,
        PD.UpVotes,
        PD.DownVotes,
        ROW_NUMBER() OVER (ORDER BY PD.ViewCount DESC) AS ViewRank
    FROM PostDetails PD
)
SELECT 
    US.DisplayName,
    US.TotalPosts,
    US.TotalComments,
    US.TotalScore,
    US.TotalBadges,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.AnswerCount,
    RP.UpVotes,
    RP.DownVotes
FROM UserStats US
LEFT JOIN RankingPost RP ON US.UserId = RP.PostId
WHERE US.Rank <= 10 
ORDER BY US.TotalScore DESC, RP.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;
