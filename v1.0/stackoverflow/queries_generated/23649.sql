WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        COALESCE(P.AnswerCount, 0) AS TotalAnswers,
        COALESCE(P.ViewCount, 0) AS TotalViews,
        COUNT(C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2 OR NULL) AS TotalUpVotes,  -- Only counting upvotes
        SUM(V.VoteTypeId = 3 OR NULL) AS TotalDownVotes -- Only counting downvotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate > (CURRENT_DATE - INTERVAL '30 days') -- Posts in the last 30 days
    GROUP BY 
        P.Id, P.Title, P.PostTypeId, P.AnswerCount, P.ViewCount
),
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        MAX(PH.CreationDate) AS LastModificationDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
),
QuestionStatistics AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.TotalAnswers,
        PS.TotalViews,
        PS.CommentCount,
        PS.TotalUpVotes,
        PS.TotalDownVotes,
        U.UserId,
        U.Reputation,
        U.GoldBadges,
        U.SilverBadges,
        U.BronzeBadges,
        PH.LastModificationDate
    FROM 
        PostSummary PS
    JOIN 
        UserBadges U ON PS.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE OwnerUserId = U.UserId)
    LEFT JOIN 
        PostHistoryStats PH ON PS.PostId = PH.PostId AND PH.PostHistoryTypeId = 10 -- Only closed posts
    WHERE 
        PS.PostTypeId = 1 -- Questions only
)
SELECT 
    QS.Title,
    QS.TotalAnswers,
    QS.TotalViews,
    QS.CommentCount,
    QS.TotalUpVotes,
    QS.TotalDownVotes,
    COALESCE(U.GoldBadges, 0) AS GoldBadges,
    COALESCE(U.SilverBadges, 0) AS SilverBadges,
    COALESCE(U.BronzeBadges, 0) AS BronzeBadges,
    (QS.TotalUpVotes - QS.TotalDownVotes) AS VoteBalance,
    CASE 
        WHEN QS.LastModificationDate IS NULL THEN 'Never Modified'
        WHEN QS.LastModificationDate < (CURRENT_TIMESTAMP - INTERVAL '1 week') THEN 'Stale'
        ELSE 'Recently Active'
    END AS ActivityStatus
FROM 
    QuestionStatistics QS
JOIN 
    Users U ON QS.UserId = U.Id
ORDER BY 
    VoteBalance DESC, QS.TotalViews DESC
LIMIT 10;
