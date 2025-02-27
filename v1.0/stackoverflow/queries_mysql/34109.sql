
WITH RECURSIVE UserBadgeCounts AS (
    SELECT 
        UserId, 
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(BC.TotalBadges, 0) AS TotalBadges,
        BC.GoldBadges,
        BC.SilverBadges,
        BC.BronzeBadges,
        @rank := @rank + 1 AS Rank
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts BC ON U.Id = BC.UserId
    JOIN (SELECT @rank := 0) r
    WHERE 
        U.Reputation > 0
    ORDER BY U.Reputation DESC
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.Id AS OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        COALESCE((SELECT SUM(V.BountyAmount) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 8), 0) AS TotalBounty
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
),
AnswerDetails AS (
    SELECT 
        A.Id AS AnswerId,
        A.ParentId AS QuestionId,
        A.Score AS AnswerScore,
        A.CreationDate AS AnswerCreationDate,
        D.OwnerUserId,
        D.OwnerDisplayName,
        D.CommentCount,
        D.TotalBounty,
        @answerRank := IF(@prevParentId = A.ParentId, @answerRank + 1, 1) AS AnswerRank,
        @prevParentId := A.ParentId
    FROM 
        Posts A
    JOIN 
        PostDetails D ON A.ParentId = D.PostId
    JOIN (SELECT @answerRank := 0, @prevParentId := NULL) ar
    WHERE 
        A.PostTypeId = 2
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.TotalBadges,
    TU.GoldBadges,
    TU.SilverBadges,
    TU.BronzeBadges,
    PD.Title AS QuestionTitle,
    PD.ViewCount,
    PD.Score AS QuestionScore,
    COALESCE(AD.AnswerId, -1) AS AcceptedAnswerId,
    AD.AnswerScore AS MostSupportedAnswerScore,
    AD.AnswerCreationDate AS MostSupportedAnswerDate,
    PD.CommentCount,
    PD.TotalBounty AS QuestionTotalBounty,
    CASE 
        WHEN PD.ViewCount > 1000 THEN 'High Lead'
        WHEN PD.ViewCount BETWEEN 500 AND 1000 THEN 'Moderate Lead'
        ELSE 'Low Lead'
    END AS EngagementLevel
FROM 
    TopUsers TU
JOIN 
    PostDetails PD ON TU.UserId = PD.OwnerUserId
LEFT JOIN 
    AnswerDetails AD ON PD.PostId = AD.QuestionId AND AD.AnswerRank = 1
WHERE 
    TU.Rank <= 10
ORDER BY 
    TU.Reputation DESC, 
    PD.ViewCount DESC;
