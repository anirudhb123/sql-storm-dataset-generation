WITH TagStats AS (
    SELECT 
        TRIM(UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><'))) AS TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        MAX(U.Reputation) AS MaxReputation,
        COUNT(B.Id) AS BadgeCount,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - U.CreationDate)) / 3600) AS AverageAccountAgeHours
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostInsights AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        ST_DistanceSphere(
            point(EXTRACT(EPOCH FROM P.CreationDate), P.ViewCount), 
            point(EXTRACT(EPOCH FROM NOW()), 1000)
        ) AS PopularityIndex,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title
)
SELECT 
    T.TagName,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    U.UserId,
    U.MaxReputation,
    U.BadgeCount,
    U.AverageAccountAgeHours,
    P.PostId,
    P.Title,
    P.PopularityIndex,
    P.CommentCount,
    P.UpVotes
FROM 
    TagStats T
JOIN 
    UserReputation U ON U.BadgeCount > 5  -- Focusing on users with significant recognition
JOIN 
    PostInsights P ON P.CommentCount > 0 -- Limit to popular posts with comments
WHERE 
    T.PostCount > 10 -- Filter for tags with a substantial number of posts
ORDER BY 
    T.PostCount DESC, 
    U.MaxReputation DESC,
    P.PopularityIndex DESC;
