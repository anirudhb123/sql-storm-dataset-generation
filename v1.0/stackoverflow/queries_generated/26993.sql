WITH PostTagCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(T.TagName) AS TagCount,
        P.OwnerUserId,
        P.Title
    FROM 
        Posts P
    LEFT JOIN 
        Tags T ON POSITION(T.TagName IN P.Tags) > 0
    WHERE 
        P.PostTypeId = 1 -- Only consider questions
    GROUP BY 
        P.Id, P.OwnerUserId, P.Title
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName
    FROM 
        Users U
    WHERE 
        U.Reputation >= 1000 -- Only include users with high reputation
),
UserPostStats AS (
    SELECT 
        U.UserId,
        COUNT(P.Id) AS QuestionCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers
    FROM 
        UserReputation U
    JOIN 
        Posts P ON P.OwnerUserId = U.UserId
    WHERE 
        P.PostTypeId = 1 -- Only interested in questions
    GROUP BY 
        U.UserId
),
PostActivity AS (
    SELECT 
        PH.PostId,
        STRING_AGG(PH.Comment, '; ') AS HistoryComments
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12) -- Close, Reopen and Delete events
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName,
    UPS.QuestionCount,
    UPS.TotalViews,
    UPS.TotalAnswers,
    PTC.TagCount,
    COALESCE(PA.HistoryComments, 'No significant actions') AS ImportantPostActions
FROM 
    UserPostStats UPS
JOIN 
    UserReputation U ON UPS.UserId = U.UserId
LEFT JOIN 
    PostTagCounts PTC ON PTC.OwnerUserId = U.UserId
LEFT JOIN 
    PostActivity PA ON PA.PostId = PTC.PostId
ORDER BY 
    U.Reputation DESC, 
    UPS.QuestionCount DESC;
