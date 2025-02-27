WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.LastActivityDate,
        P.Socre,
        P.AnswerCount,
        P.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 -- Only questions
),

TopUserPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.CreationDate,
        RP.LastActivityDate
    FROM 
        RankedPosts RP
    WHERE 
        RP.PostRank <= 5 -- Top 5 posts per user
)

SELECT 
    U.DisplayName AS UserName,
    COUNT(TP.PostId) AS PostCount,
    STRING_AGG(DISTINCT TP.Title, '; ') AS TopPostTitles,
    MIN(TP.CreationDate) AS FirstPostDate,
    MAX(TP.LastActivityDate) AS LastPostDate
FROM 
    Users U
LEFT JOIN 
    TopUserPosts TP ON U.Id = TP.OwnerDisplayName
GROUP BY 
    U.DisplayName
HAVING 
    COUNT(TP.PostId) > 0 -- Only include users who have questions
ORDER BY 
    PostCount DESC, U.DisplayName;
