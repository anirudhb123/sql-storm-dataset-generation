WITH PostTagCounts AS (
    SELECT 
        post.Id AS PostId,
        COUNT(*) AS TagCount,
        STRING_AGG(tags.TagName, ', ') AS TagList
    FROM 
        Posts post
    JOIN 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(post.Tags, 2, LENGTH(post.Tags) - 2), '><')) AS tag ON TRUE
    JOIN 
        Tags tags ON tags.TagName = tag
    GROUP BY 
        post.Id
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        MAX(P.CreationDate) AS LastActivity
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    GROUP BY 
        U.Id
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.ViewCount,
        P.AnswerCount,
        COALESCE(PH.CreationDate, P.CreationDate) AS MostRecentEdit,
        COALESCE(PH.RevisionGUID, 'N/A') AS LastRevisionGUID
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(CASE WHEN COALESCE(PH.PostHistoryTypeId, 0) IN (10, 11) THEN 1 ELSE 0 END) AS PostsClosedOrReopened
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        U.Id
)

SELECT 
    U.DisplayName,
    UA.TotalScore,
    UAS.QuestionsAsked,
    UAS.AnswersGiven,
    UAS.PostsClosedOrReopened,
    PTC.TagCount,
    PTC.TagList,
    PS.Title,
    PS.MostRecentEdit,
    PS.LastRevisionGUID
FROM 
    UserActivity UA
JOIN 
    UserPostStats UAS ON UA.UserId = UAS.UserId
JOIN 
    PostTagCounts PTC ON PTC.PostId IN (
        SELECT Id FROM Posts WHERE OwnerUserId = UAS.UserId
    )
JOIN 
    PostStatistics PS ON PS.PostId IN (
        SELECT Id FROM Posts WHERE OwnerUserId = UAS.UserId
    )
ORDER BY 
    UA.TotalScore DESC, 
    UAS.QuestionsAsked DESC;
