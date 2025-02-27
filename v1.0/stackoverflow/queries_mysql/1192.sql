
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(T.Tags, ',', numbers.n), ',', -1)) AS TagName,
        COUNT(DISTINCT P.Id) AS TagCount
    FROM 
        Posts P
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
         UNION ALL SELECT 10) numbers ON CHAR_LENGTH(T.Tags) - CHAR_LENGTH(REPLACE(T.Tags, ',', '')) >= numbers.n - 1
    JOIN 
        (SELECT P.Tags) T ON P.Id IS NOT NULL
    GROUP BY 
        TagName
    HAVING 
        COUNT(DISTINCT P.Id) > 5
),
RecentEdits AS (
    SELECT 
        H.PostId,
        H.UserDisplayName,
        H.CreationDate,
        @row_number := IF(@current_post_id = H.PostId, @row_number + 1, 1) AS EditRank,
        @current_post_id := H.PostId
    FROM 
        PostHistory H,
        (SELECT @row_number := 0, @current_post_id := NULL) AS vars
    WHERE 
        H.PostHistoryTypeId IN (4, 5, 6) 
        AND H.CreationDate > (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY)
    ORDER BY 
        H.PostId, H.CreationDate DESC
)
SELECT 
    PS.DisplayName AS UserName,
    PS.Reputation,
    COALESCE(TT.TagName, 'No Tags') AS Tag,
    PS.PostCount,
    PS.QuestionCount,
    PS.AcceptedAnswers,
    RE.UserDisplayName AS LastEditor,
    RE.CreationDate AS LastEditDate
FROM 
    UserStats PS
LEFT JOIN 
    TopTags TT ON PS.PostCount > 10 AND TT.TagCount > 5
LEFT JOIN 
    RecentEdits RE ON PS.UserId = RE.PostId AND RE.EditRank = 1
WHERE 
    PS.Reputation > 200 AND PS.QuestionCount > 5
ORDER BY 
    PS.Reputation DESC,
    PS.PostCount DESC
LIMIT 100;
