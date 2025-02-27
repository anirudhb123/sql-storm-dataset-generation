WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LatestPostDate
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE 
        P.PostTypeId = 1 -- Only for Questions
    GROUP BY 
        T.TagName
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS AnsweredQuestions,
        SUM(P.Score) AS TotalScore,
        AVG(P.Score) AS AverageScore,
        RANK() OVER (ORDER BY SUM(P.Score) DESC) AS ScoreRank
    FROM 
        Users U
    JOIN 
        Posts P ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 2 -- Only for Answers
    GROUP BY 
        U.Id, U.DisplayName
),
RecentChanges AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastChangeDate,
        STRING_AGG(DISTINCT CASE 
            WHEN PH.PostHistoryTypeId IN (10, 11) THEN 
                (SELECT Name FROM CloseReasonTypes WHERE Id = CAST(PH.Comment AS INT))
            ELSE 
                PH.Comment 
            END, ', ') AS ChangeComments
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        T.TagName,
        PS.TotalViews,
        PS.TotalScore,
        U.DisplayName AS Author,
        U.Reputation,
        COALESCE(RC.ChangeComments, 'No changes') AS LatestChanges,
        COALESCE(RC.LastChangeDate, 'Never') AS LastChangeDate
    FROM 
        Posts P
    JOIN 
        Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        RecentChanges RC ON P.Id = RC.PostId
    JOIN 
        TagStats PS ON T.TagName = PS.TagName
    WHERE 
        P.PostTypeId = 1 -- Only for Questions
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.TagName,
    PS.TotalViews,
    PS.TotalScore,
    P.AverageScore AS TagAverageScore,
    PS.Author,
    PS.Reputation,
    PS.LatestChanges,
    PS.LastChangeDate,
    CASE 
        WHEN TUS.ScoreRank <= 5 THEN 'Top User' 
        ELSE 'Regular User' 
    END AS UserCategory
FROM 
    PostSummary PS
LEFT JOIN 
    TopUsers TUS ON PS.Author = TUS.DisplayName
ORDER BY 
    PS.TotalScore DESC, PS.TotalViews DESC;
