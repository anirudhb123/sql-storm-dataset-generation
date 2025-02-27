WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END), 0) AS VoteCount,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
ClosedQuestionStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS ClosedQuestions,
        COUNT(DISTINCT P.Id) AS TotalClosedPosts
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        P.OwnerUserId
),
AggregateStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.VoteCount,
        U.GoldBadges,
        U.SilverBadges,
        U.BronzeBadges,
        COALESCE(CQS.ClosedQuestions, 0) AS ClosedQuestions,
        COALESCE(CQS.TotalClosedPosts, 0) AS TotalClosedPosts,
        U.PostCount,
        U.AverageScore,
        U.ReputationRank
    FROM 
        UserStats U
    LEFT JOIN 
        ClosedQuestionStats CQS ON U.UserId = CQS.OwnerUserId
)
SELECT 
    A.DisplayName,
    A.VoteCount,
    A.GoldBadges,
    A.SilverBadges,
    A.BronzeBadges,
    A.ClosedQuestions,
    A.TotalClosedPosts,
    A.PostCount,
    A.AverageScore,
    CASE 
        WHEN A.ReputationRank <= 10 THEN 'Top Contributor'
        WHEN A.ReputationRank BETWEEN 11 AND 50 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributorLevel
FROM 
    AggregateStats A
WHERE 
    A.ClosedQuestions > (SELECT AVG(ClosedQuestions) FROM ClosedQuestionStats) 
    AND A.PostCount > 5
ORDER BY 
    A.VoteCount DESC, A.AverageScore DESC;

-- Additional edge case involving NULL logic, string manipulation using tags, and complex predicates.
SELECT 
    T.TagName,
    COUNT(DISTINCT P.Id) AS PostCount
FROM 
    Tags T
LEFT JOIN 
    Posts P ON POSITION(',' || T.TagName || ',' IN ',' || P.Tags || ',') > 0
WHERE 
    T.IsModeratorOnly = 0
AND 
    (P.ClosedDate IS NULL OR P.ClosedDate > CURRENT_TIMESTAMP - INTERVAL '30 days')
GROUP BY 
    T.TagName
HAVING 
    COUNT(DISTINCT P.Id) > 5
ORDER BY 
    PostCount DESC;

-- Utilizing a STRING_AGG to handle unusual edges involving comments
SELECT 
    P.Id AS PostId,
    STRING_AGG(C.Text, ' | ') AS CommentTexts
FROM 
    Posts P
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.AcceptedAnswerId IS NOT NULL
GROUP BY 
    P.Id
HAVING 
    COUNT(C.Id) > (SELECT AVG(CommentCount) FROM Posts)
ORDER BY 
    P.Id DESC;
