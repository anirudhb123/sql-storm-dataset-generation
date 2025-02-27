WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId 
    GROUP BY 
        U.Id
),
QuestionStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalQuestions,
        COUNT(A.Id) AS TotalAnswers,
        AVG(P.Score) AS AvgQuestionScore
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId 
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.OwnerUserId
), 
VoteSummary AS (
    SELECT 
        V.UserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotesCount
    FROM 
        Votes V 
    GROUP BY 
        V.UserId
),
LinkageDetails AS (
    SELECT 
        L.PostId,
        COUNT(L.RelatedPostId) AS LinkedPostCount
    FROM 
        PostLinks L
    GROUP BY 
        L.PostId
)
SELECT 
    UR.DisplayName,
    COALESCE(UR.Reputation, 0) AS Reputation,
    COALESCE(US.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(US.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(US.AvgQuestionScore, 0) AS AvgQuestionScore,
    COALESCE(VS.UpVotesCount, 0) AS UpVotesCount,
    COALESCE(VS.DownVotesCount, 0) AS DownVotesCount,
    COALESCE(LD.LinkedPostCount, 0) AS LinkedPostCount,
    CONCAT('Badges - Gold: ', COALESCE(UR.GoldBadges, 0), 
           ', Silver: ', COALESCE(UR.SilverBadges, 0), 
           ', Bronze: ', COALESCE(UR.BronzeBadges, 0)) AS BadgeSummary
FROM 
    UserReputation UR
LEFT JOIN 
    QuestionStats US ON UR.UserId = US.OwnerUserId
LEFT JOIN 
    VoteSummary VS ON UR.UserId = VS.UserId
LEFT JOIN 
    LinkageDetails LD ON EXISTS (
        SELECT 1 
        FROM Posts P 
        WHERE P.OwnerUserId = UR.UserId
    )
ORDER BY 
    UR.Reputation DESC, 
    UR.DisplayName ASC;
