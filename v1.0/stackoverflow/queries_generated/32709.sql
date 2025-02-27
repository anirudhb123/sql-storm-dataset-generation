WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
        AND P.PostTypeId = 1 -- Considering only Questions
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS NumberOfQuestions,
        SUM(P.Score) AS TotalScore,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    GROUP BY 
        U.Id
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS EditDate,
        PH.UserId AS EditorId,
        U.DisplayName AS EditorDisplayName,
        PH.Comment,
        PH.PostHistoryTypeId
    FROM 
        PostHistory PH
    JOIN 
        Users U ON PH.UserId = U.Id
    WHERE 
        PH.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    TP.DisplayName AS TopUser,
    TP.NumberOfQuestions,
    TP.TotalScore,
    RP.PostId,
    RP.Title,
    RP.CreationDate AS QuestionDate,
    RP.Score AS QuestionScore,
    RP.ViewCount,
    RP.AnswerCount,
    COALESCE(RPH.EditDate, 'No Edits') AS LastEditDate,
    COALESCE(RPH.EditorDisplayName, 'N/A') AS LastEditor,
    RPH.Comment AS LastEditComment
FROM 
    TopUsers TP
JOIN 
    RankedPosts RP ON TP.UserId = RP.OwnerDisplayName
LEFT JOIN 
    RecentPostHistory RPH ON RP.PostId = RPH.PostId
WHERE 
    TP.UserRank <= 10
ORDER BY 
    TP.NumberOfQuestions DESC, RP.Score DESC;
