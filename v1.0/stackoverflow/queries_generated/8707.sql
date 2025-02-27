WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.Tags,
        COUNT(C.Id) AS CommentCount,
        STRING_AGG(C.Text, '; ') AS Comments,
        COALESCE(HT.Name, 'Unknown') AS HistoryType
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        PostHistoryTypes HT ON PH.PostHistoryTypeId = HT.Id
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.Tags, HT.Name
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.BadgeCount,
    US.TotalViews,
    US.TotalScore,
    US.PostCount,
    US.AcceptedAnswers,
    PA.PostId,
    PA.Title,
    PA.CreationDate,
    PA.ViewCount,
    PA.Score,
    PA.Tags,
    PA.CommentCount,
    PA.Comments,
    PA.HistoryType
FROM 
    UserStats US
JOIN 
    PostAnalytics PA ON US.UserId = PA.OwnerUserId
WHERE 
    US.Reputation > 1000 
ORDER BY 
    US.Reputation DESC, PA.ViewCount DESC
LIMIT 50;
