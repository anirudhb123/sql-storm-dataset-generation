WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId IN (1, 2) THEN P.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN U.Likes > 0 THEN 1 ELSE 0 END) AS LikedCount,
        COALESCE(MAX(B.Date), '1900-01-01') AS LastBadgeDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
RankedUserStats AS (
    SELECT 
        Us.*,
        RANK() OVER (ORDER BY Us.Reputation DESC, Us.TotalScore DESC) AS ReputationRank
    FROM 
        UserStats Us
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        ReputationRank
    FROM 
        RankedUserStats
    WHERE 
        Reputation >= 1000
    ORDER BY 
        ReputationRank
    LIMIT 10
)
SELECT 
    Tu.DisplayName,
    Tu.Reputation,
    Tu.PostCount,
    Tu.QuestionCount,
    Tu.AnswerCount,
    Tu.TotalScore,
    T.Tags,
    PH.Comment,
    PH.CreationDate AS LastActionDate
FROM 
    TopUsers Tu
LEFT JOIN 
    Posts P ON Tu.UserId = P.OwnerUserId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    (SELECT 
        PostId,
        STRING_AGG(TagName, ', ') AS Tags
     FROM 
        Tags T
     JOIN 
        Posts P ON T.ExcerptPostId = P.Id
     GROUP BY 
        PostId) T ON P.Id = T.PostId 
ORDER BY 
    Tu.Reputation DESC, Tu.PostCount DESC;
