WITH PostTagCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(T.Id) AS TagCount
    FROM 
        Posts P
    LEFT JOIN 
        Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE 
        P.PostTypeId = 1 -- Only questions
    GROUP BY 
        P.Id
),
UserReputationSummary AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(P.Id) AS QuestionCount,
        SUM(COALESCE(B.Class, 0)) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 -- Only questions
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS CloseDate,
        PH.UserDisplayName AS CloserName
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 -- Post Closed
)

SELECT 
    U.DisplayName AS UserDisplayName,
    U.Reputation AS UserReputation,
    UTC.QuestionCount,
    UTC.TotalBadges,
    P.Title AS QuestionTitle,
    P.CreationDate AS QuestionCreationDate,
    P.Score AS QuestionScore,
    P.ViewCount AS QuestionViewCount,
    T.TagCount AS TagCount,
    CP.CloseDate AS QuestionClosedDate,
    CP.CloserName AS CloserUserName
FROM 
    UserReputationSummary UTC
JOIN 
    Posts P ON UTC.UserId = P.OwnerUserId AND P.PostTypeId = 1 -- Only questions
LEFT JOIN 
    PostTagCounts T ON P.Id = T.PostId
LEFT JOIN 
    ClosedPosts CP ON P.Id = CP.PostId
WHERE 
    UTC.Reputation > 1000 -- Filter for users with higher reputation
ORDER BY 
    UTC.Reputation DESC, 
    P.Score DESC
LIMIT 50; -- Get top 50 results
