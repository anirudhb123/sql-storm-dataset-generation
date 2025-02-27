
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        SUM(ISNULL(P.Score, 0)) AS TotalScore,
        SUM(ISNULL(P.ViewCount, 0)) AS TotalViews
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopTags AS (
    SELECT 
        T.TagName,
        SUM(ISNULL(P.ViewCount, 0)) AS TagTotalViews,
        COUNT(DISTINCT P.Id) AS TagPostCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' + T.TagName + '%'
    GROUP BY T.TagName
    ORDER BY TagTotalViews DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
),
RecentEdits AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.Comment,
        P.Title
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.CreationDate >= DATEADD(MONTH, -1, GETDATE())
    ORDER BY PH.CreationDate DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.TotalQuestions,
    US.TotalAnswers,
    US.TotalScore,
    US.TotalViews,
    TT.TagName,
    TT.TagTotalViews,
    TT.TagPostCount,
    RE.PostId AS RecentEditPostId,
    RE.Title AS RecentEditTitle,
    RE.CreationDate AS RecentEditDate,
    RE.Comment AS RecentEditComment
FROM UserStats US
LEFT JOIN TopTags TT ON 1=1
LEFT JOIN RecentEdits RE ON RE.UserId = US.UserId
WHERE US.Reputation > 1000
ORDER BY US.Reputation DESC, TT.TagTotalViews DESC, RE.CreationDate DESC;
