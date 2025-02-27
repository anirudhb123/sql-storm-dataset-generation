WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties, 
        COUNT(DISTINCT V.PostId) AS BountyCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(V.BountyAmount), 0) DESC) AS BountyRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId AND V.VoteTypeId = 8 -- BountyStart
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
), 
RankedUsers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY TotalBounties DESC, PostCount DESC) AS RowNum
    FROM 
        UserStats
)
SELECT 
    R.UserId,
    R.DisplayName,
    R.TotalBounties,
    R.BountyCount,
    R.QuestionCount,
    R.AnswerCount,
    R.BountyRank
FROM 
    RankedUsers R
WHERE 
    R.RowNum <= 10
ORDER BY 
    R.TotalBounties DESC;

SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    COALESCE(PT.Name, 'Not Specified') AS PostType,
    COALESCE(COUNT(DISTINCT C.Id), 0) AS CommentCount
FROM 
    Posts P
LEFT JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.CreationDate >= DATEADD(MONTH, -1, GETDATE())
GROUP BY 
    P.Id, PT.Name
HAVING 
    COUNT(DISTINCT C.Id) > 0
ORDER BY 
    CommentCount DESC
LIMIT 5;

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    (
        SELECT COUNT(*) 
        FROM Badges B 
        WHERE B.UserId = U.Id AND B.Class = 1
    ) AS GoldBadges,
    (
        SELECT COUNT(*) 
        FROM Badges B 
        WHERE B.UserId = U.Id AND B.Class = 2
    ) AS SilverBadges,
    (
        SELECT COUNT(*) 
        FROM Badges B 
        WHERE B.UserId = U.Id AND B.Class = 3
    ) AS BronzeBadges
FROM 
    Users U
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC;

SELECT 
    *
FROM 
    Tags T
WHERE 
    T.Count > (
        SELECT AVG(Count) FROM Tags
    )
ORDER BY 
    T.Count DESC;
