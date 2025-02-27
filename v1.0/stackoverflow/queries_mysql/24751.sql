
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        U.LastAccessDate,
        CASE 
            WHEN U.Reputation >= 1000 THEN 'Gold'
            WHEN U.Reputation BETWEEN 500 AND 999 THEN 'Silver'
            ELSE 'Bronze'
        END AS ReputationTier
    FROM 
        Users U
), PostSummary AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.ViewCount, 
        P.AnswerCount, 
        P.CreationDate, 
        U.DisplayName AS OwnerDisplayName,
        COALESCE(PH.RevisionCount, 0) AS RevisionCount
    FROM 
        Posts P
    LEFT JOIN (
        SELECT PH.PostId, COUNT(*) AS RevisionCount
        FROM PostHistory PH
        GROUP BY PH.PostId
    ) PH ON PH.PostId = P.Id
    JOIN Users U ON P.OwnerUserId = U.Id
),
TopPosts AS (
    SELECT 
        PS.PostId, 
        PS.Title, 
        PS.ViewCount, 
        PS.AnswerCount, 
        PS.CreationDate, 
        PS.OwnerDisplayName,
        @row_number := IF(@current_owner = PS.OwnerDisplayName, @row_number + 1, 1) AS Rank,
        @current_owner := PS.OwnerDisplayName
    FROM 
        PostSummary PS, (SELECT @row_number := 0, @current_owner := '') AS vars
    WHERE 
        PS.ViewCount IS NOT NULL 
        AND PS.CreationDate >= (NOW() - INTERVAL 1 YEAR)
    ORDER BY 
        PS.OwnerDisplayName, PS.ViewCount DESC
)
SELECT 
    UP.DisplayName, 
    UP.Reputation, 
    TP.Title, 
    TP.ViewCount, 
    TP.AnswerCount, 
    TP.CreationDate,
    UP.ReputationTier,
    CASE 
        WHEN TP.AnswerCount = 0 THEN 'No Answers Yet' 
        ELSE 'Has Answers' 
    END AS AnswerStatus
FROM 
    UserReputation UP
JOIN 
    TopPosts TP ON UP.UserId = (
        SELECT P.OwnerUserId 
        FROM Posts P 
        WHERE P.Id = TP.PostId
    )
WHERE 
    UP.Reputation >= (
        SELECT AVG(Reputation) 
        FROM UserReputation
    )
ORDER BY 
    UP.Reputation DESC, 
    TP.ViewCount DESC
LIMIT 10;
