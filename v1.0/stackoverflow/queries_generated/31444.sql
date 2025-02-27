WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.ParentId,
        P.CreationDate,
        P.AnswerCount,
        P.ViewCount,
        P.Score,
        0 AS Level
    FROM Posts P
    WHERE P.PostTypeId = 1  -- Start with Questions
    UNION ALL
    SELECT 
        P.Id,
        P.Title,
        P.PostTypeId,
        P.ParentId,
        P.CreationDate,
        P.AnswerCount,
        P.ViewCount,
        P.Score,
        Level + 1
    FROM Posts P
    INNER JOIN RecursivePostHierarchy R ON P.ParentId = R.PostId
),
PostVoteDetails AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes V
    GROUP BY V.PostId
),
UserRecommendations AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        AVG(U.Reputation) OVER() AS AvgReputation,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostStatistics AS (
    SELECT 
        PH.PostId,
        PH.Title,
        PH.CreationDate,
        COALESCE(PD.UpVotes, 0) AS UpVotes,
        COALESCE(PD.DownVotes, 0) AS DownVotes,
        COALESCE(PD.TotalVotes, 0) AS TotalVotes,
        U.UserId,
        U.DisplayName,
        U.AvgReputation
    FROM RecursivePostHierarchy PH
    LEFT JOIN PostVoteDetails PD ON PH.PostId = PD.PostId
    LEFT JOIN UserRecommendations U ON PH.PostId = U.UserId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.UpVotes,
    PS.DownVotes,
    PS.TotalVotes,
    PS.DisplayName,
    PS.AvgReputation,
    CASE
        WHEN PS.TotalVotes > 100 THEN 'Popular'
        WHEN PS.AvgReputation >= 500 THEN 'Expert Contributor'
        ELSE 'Newbie'
    END AS UserStatus,
    CONCAT('Post ID: ', PS.PostId, ' | Title: ', PS.Title) AS PostInfo
FROM PostStatistics PS
WHERE PS.UpVotes IS NOT NULL
  AND PS.DownVotes IS NOT NULL
ORDER BY PS.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;

