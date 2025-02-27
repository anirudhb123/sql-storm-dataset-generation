WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT V.PostId) AS TotalVotes,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(COUNT(C.ID), 0) AS TotalComments,
        COUNT(DISTINCT PH.UserId) AS TotalHistories,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS LatestHistoryRow,
        MAX(PH.CreationDate) OVER (PARTITION BY P.Id) AS RecentEditDate
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year' -- Only consider recent posts
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount
),
QuestionStats AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.ViewCount,
        PS.TotalComments,
        PS.TotalHistories,
        PS.RecentEditDate,
        U.DisplayName AS AuthorName,
        U.Reputation,
        U.AccountId,
        (US.Upvotes - US.Downvotes) AS NetVotes
    FROM PostStatistics PS
    JOIN Posts P ON PS.PostId = P.Id
    JOIN Users U ON P.OwnerUserId = U.Id
    JOIN UserVotes US ON U.Id = US.UserId
    WHERE P.PostTypeId = 1 -- Independently usable with only Questions
)
SELECT 
    QS.PostId,
    QS.Title,
    QS.Score,
    QS.ViewCount,
    QS.TotalComments,
    QS.TotalHistories,
    QS.RecentEditDate,
    QS.AuthorName,
    QS.Reputation,
    QS.NetVotes,
    CASE 
        WHEN QS.Reputation IS NULL THEN 'No Reputation Yet'
        ELSE 'Reputation: ' || QS.Reputation
    END AS ReputationStatus,
    CASE 
        WHEN QS.NetVotes > 10 THEN 'Highly Engaging'
        WHEN QS.NetVotes BETWEEN 5 AND 10 THEN 'Moderately Engaging'
        ELSE 'Less Engaging'
    END AS EngagementLevel,
    CASE 
        WHEN QS.TotalComments > 0 THEN 'This post has comments'
        ELSE 'This post has no comments'
    END AS CommentStatus,
    COUNT(DISTINCT PH.Id) FILTER (WHERE PH.PostHistoryTypeId IN (10, 11, 12)) AS ActionCounts
FROM QuestionStats QS
LEFT JOIN PostHistory PH ON QS.PostId = PH.PostId
GROUP BY 
    QS.PostId, QS.Title, QS.Score, QS.ViewCount,
    QS.TotalComments, QS.TotalHistories, QS.RecentEditDate,
    QS.AuthorName, QS.Reputation, QS.NetVotes
ORDER BY QS.Score DESC, QS.ViewCount DESC
LIMIT 100;
