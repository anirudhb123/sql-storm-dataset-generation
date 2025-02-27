WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionsAnswered,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswersGiven
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    GROUP BY 
        U.Id
),
BadgeCount AS (
    SELECT 
        UserId,
        COUNT(Id) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
FilteredPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(PA.Score, 0) AS AcceptedAnswerScore,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        Posts PA ON P.AcceptedAnswerId = PA.Id
    LEFT JOIN 
        LATERAL string_to_array(P.Tags, '>') AS T
    GROUP BY 
        P.Id, PA.Score
    HAVING 
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) > 0
),
RankedPosts AS (
    SELECT 
        FP.*, 
        RANK() OVER (PARTITION BY FP.ViewCount ORDER BY FP.CreationDate DESC) AS Rank
    FROM 
        FilteredPosts FP
    WHERE 
        FP.ViewCount IS NOT NULL
),
FinalReport AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        UVS.TotalUpVotes,
        UVS.TotalDownVotes,
        BC.BadgeCount,
        RP.*
    FROM 
        UserVoteSummary UVS
    JOIN 
        BadgeCount BC ON UVS.UserId = BC.UserId
    JOIN 
        RankedPosts RP ON RP.ViewCount > 10
    JOIN 
        Users U ON U.Id = UVS.UserId
)
SELECT 
    DisplayName,
    Reputation,
    TotalUpVotes,
    TotalDownVotes,
    BadgeCount,
    Title,
    CreationDate,
    ViewCount,
    AcceptedAnswerScore,
    Tags,
    COALESCE(ClosedPostCount.ClosedPosts, 0) AS ClosedPosts
FROM 
    FinalReport
LEFT JOIN 
    (SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS ClosedPosts
     FROM 
        Posts P
     WHERE 
        P.ClosedDate IS NOT NULL
     GROUP BY 
        P.OwnerUserId) AS ClosedPostCount
ON 
    FinalReport.UserId = ClosedPostCount.OwnerUserId
WHERE 
    Reputation BETWEEN 100 AND 500
    AND (BadgeCount >= 5 OR TotalUpVotes > TotalDownVotes)
ORDER BY 
    Tags, 
    Reputation DESC;
