WITH HistoricalVotes AS (
    SELECT 
        P.Id AS PostId,
        H.PostHistoryTypeId,
        COUNT(V.Id) AS VoteCount,
        MAX(H.CreationDate) AS LastVoteDate
    FROM 
        PostHistory H
    JOIN 
        Posts P ON P.Id = H.PostId
    LEFT JOIN 
        Votes V ON V.PostId = P.Id 
    WHERE 
        H.PostHistoryTypeId IN (10, 11, 12, 13) -- Considering only close/open/delete events
    GROUP BY 
        P.Id, H.PostHistoryTypeId
),
AcceptedAnswers AS (
    SELECT
        P.Id AS QuestionId,
        COUNT(A.Id) AS AcceptedCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON A.AcceptedAnswerId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = A.Id AND V.VoteTypeId = 2 -- Upvotes only
    WHERE 
        P.PostTypeId = 1 -- Questions
    GROUP BY 
        P.Id
),
TagInfo AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(UPLag.Views) AS AvgViewsPerPost,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        STRING_AGG(DISTINCT B.Name, ', ') AS BadgeNames
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    LEFT JOIN 
        Badges B ON B.UserId = P.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, Views FROM Posts) UPLag ON UPLag.PostId = P.Id
    GROUP BY 
        T.TagName
)
SELECT 
    T.TagName,
    T.PostCount,
    T.AvgViewsPerPost,
    COALESCE(A.AcceptedCount, 0) AS AcceptedAnswerCount,
    COALESCE(A.Upvotes, 0) AS TotalUpvotes,
    COALESCE(B.BadgeCount, 0) AS TotalBadges,
    COALESCE(B.BadgeNames, 'None') AS BadgeNames,
    COUNT(DISTINCT V.PostId) AS ClosedPostCount,
    STRING_AGG(DISTINCT U.DisplayName, ', ') AS VoterDisplayNames
FROM 
    TagInfo T
LEFT JOIN 
    AcceptedAnswers A ON A.QuestionId = T.PostCount
LEFT JOIN 
    HistoricalVotes V ON V.PostId = T.PostCount
LEFT JOIN 
    Users U ON U.Id IN (SELECT DISTINCT UserId FROM Votes WHERE PostId = V.PostId)
WHERE 
    T.PostCount > 5 -- Arbitrary filter for posts per tag
GROUP BY 
    T.TagName, A.AcceptedCount, A.Upvotes, B.BadgeCount, B.BadgeNames
HAVING 
    COUNT(DISTINCT V.PostId) >= 1 -- Having at least one closed post
ORDER BY 
    T.PostCount DESC, COALESCE(A.Upvotes, 0) DESC;
