WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        DENSE_RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 -- Only questions
),

AnswerStats AS (
    SELECT 
        P.Id AS PostId,
        COUNT(A.Id) AS AnswerCount,
        SUM(A.Score) AS TotalAnswerScore
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId -- Joining answers to questions
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id
),

UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    RP.OwnerDisplayName,
    AS.AnswerCount,
    AS.TotalAnswerScore,
    UB.BadgeCount,
    UB.HighestBadgeClass,
    CASE 
        WHEN UR.rank = 1 THEN 'Newest'
        WHEN UR.rank <= 5 THEN 'Top 5'
        ELSE 'Others'
    END AS RankCategory
FROM 
    RankedPosts RP
LEFT JOIN 
    AnswerStats AS ON RP.PostId = AS.PostId
LEFT JOIN 
    UserBadges UB ON RP.OwnerUserId = UB.UserId
WHERE 
    RP.Rank <= 10
ORDER BY 
    RP.CreationDate DESC;

-- Also combining results for posts without answers
UNION ALL

SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    U.DisplayName AS OwnerDisplayName,
    0 AS AnswerCount,
    0 AS TotalAnswerScore,
    UB.BadgeCount,
    UB.HighestBadgeClass,
    'No Answers' AS RankCategory
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
WHERE 
    P.PostTypeId = 1 AND
    NOT EXISTS (
        SELECT 1 FROM Posts A WHERE A.ParentId = P.Id
    )
ORDER BY 
    CreationDate DESC;
