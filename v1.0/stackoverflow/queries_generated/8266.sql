WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(VoteType = 'upvote') AS TotalUpVotes,
        SUM(VoteType = 'downvote') AS TotalDownVotes,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
BadgeSummary AS (
    SELECT 
        UserId,
        COUNT(*) FILTER (WHERE Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE Class = 3) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostHistorySummary AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS HistoryCount,
        COUNT(DISTINCT PH.PostId) AS PostRevisionCount
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        PH.UserId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.TotalComments,
    US.TotalUpVotes,
    US.TotalDownVotes,
    US.Questions,
    US.Answers,
    COALESCE(BS.GoldBadges, 0) AS GoldBadges,
    COALESCE(BS.SilverBadges, 0) AS SilverBadges,
    COALESCE(BS.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PHS.HistoryCount, 0) AS RecentHistoryCount,
    COALESCE(PHS.PostRevisionCount, 0) AS RecentPostRevisionCount
FROM 
    UserStats US
LEFT JOIN 
    BadgeSummary BS ON US.UserId = BS.UserId
LEFT JOIN 
    PostHistorySummary PHS ON US.UserId = PHS.UserId
ORDER BY 
    US.Reputation DESC
LIMIT 100;
