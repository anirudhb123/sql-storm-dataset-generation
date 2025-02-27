WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS ClosedPosts,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END), 0) AS ReopenedPosts,
        COALESCE(SUM(B.Class) * 3, 0) AS TotalGoldBadges
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
), 
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        ClosedPosts,
        ReopenedPosts,
        TotalGoldBadges,
        RANK() OVER (ORDER BY UpVotes - DownVotes DESC, TotalGoldBadges DESC) AS UserRank
    FROM 
        UserStats
), 
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVoteCount,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Accepted' 
            ELSE 'Not Accepted' 
        END AS AnswerStatus
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.Score, P.CreationDate, P.ViewCount, P.AcceptedAnswerId
), 
FinalStats AS (
    SELECT 
        RU.UserId,
        RU.DisplayName,
        RU.UpVotes,
        RU.DownVotes,
        RU.ClosedPosts,
        RU.ReopenedPosts,
        RU.TotalGoldBadges,
        PD.PostId,
        PD.Title,
        PD.Score,
        PD.CreationDate,
        PD.ViewCount,
        PD.CommentCount,
        PD.UpVoteCount,
        PD.DownVoteCount,
        PD.AnswerStatus
    FROM 
        RankedUsers RU
    INNER JOIN 
        PostDetails PD ON PD.UpVoteCount > 0 AND RU.UpVotes >= (SELECT AVG(UpVotes) FROM UserStats)
)
SELECT 
    UserId,
    DisplayName,
    ARRAY_AGG(DISTINCT Title) AS PostedTitles,
    SUM(CASE WHEN AnswerStatus = 'Accepted' THEN 1 ELSE 0 END) AS AcceptedAnswerCount,
    SUM(CommentCount) AS TotalComments,
    SUM(ViewCount) AS TotalViews,
    COUNT(DISTINCT PostId) AS TotalPosts,
    MAX(ClosedPosts) OVER () - MIN(ReopenedPosts) OVER () AS NetClosureScore
FROM 
    FinalStats
GROUP BY 
    UserId, DisplayName
ORDER BY 
    TotalViews DESC, AcceptedAnswerCount DESC
LIMIT 10;
