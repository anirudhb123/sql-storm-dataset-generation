WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (6, 10, 12) THEN 1 ELSE 0 END), 0) AS CloseVotesCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id), 0) AS TotalComments,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
),
FilteredPosts AS (
    SELECT 
        PA.*,
        ROW_NUMBER() OVER (PARTITION BY PA.OwnerUserId ORDER BY PA.CreationDate DESC) AS RowNum
    FROM PostActivity PA
    WHERE PA.Score > 0 AND PA.ViewCount > 100
),
UserBadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(*) AS TotalBadges,
        STRING_AGG(B.Name, ', ' ORDER BY B.Date DESC) AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
)
SELECT 
    U.DisplayName AS User,
    UPS.UpVotesCount,
    UPS.DownVotesCount,
    UPS.CloseVotesCount,
    FP.Title AS RecentPost,
    FP.CreationDate AS PostDate,
    FP.Score AS PostScore,
    FP.ViewCount AS PostViews,
    UBS.TotalBadges,
    UBS.BadgeNames,
    CASE 
        WHEN UPS.UpVotesCount > UPS.DownVotesCount THEN 'Positive'
        WHEN UPS.UpVotesCount < UPS.DownVotesCount THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    (SELECT COUNT(*) FROM PostHistory PH WHERE PH.UserId = U.Id AND PH.PostHistoryTypeId IN (10, 11) AND PH.CreationDate > CURRENT_DATE - INTERVAL '30 days') AS RecentCloseActions
FROM Users U
LEFT JOIN UserVoteStats UPS ON U.Id = UPS.UserId
LEFT JOIN FilteredPosts FP ON U.Id = FP.OwnerUserId AND FP.RowNum = 1
LEFT JOIN UserBadgeStats UBS ON U.Id = UBS.UserId
WHERE U.Reputation > 1000
ORDER BY U.Reputation DESC, FP.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
This query combines various constructs like Common Table Expressions (CTEs), window functions for ranking and aggregating votes, filtering logic based on scores and view counts, along with a sentiment calculation of user votes, and showcases an extensive table join structure with perplexing predicates. The corner case of extracting detailed voting history from the `PostHistory` table for "Recent Close Actions" adds complexity and potential for performance benchmarking.
