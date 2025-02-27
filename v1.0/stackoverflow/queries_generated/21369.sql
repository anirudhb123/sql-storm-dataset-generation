WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS UpvotedAnswers,
        AVG(COALESCE(P.Score, 0)) AS AvgPostScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 

PopularTags AS (
    SELECT 
        T.TagName,
        SUM(V.VoteTypeId = 2) AS TotalUpvotes,
        SUM(V.VoteTypeId = 3) AS TotalDownvotes
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON T.Id = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')::int[])
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        T.TagName
    HAVING 
        SUM(V.VoteTypeId = 2) > 10
    ORDER BY 
        TotalUpvotes DESC
    LIMIT 10
),

UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS Badges
    FROM 
        Badges B 
    GROUP BY 
        B.UserId
)

SELECT 
    UR.UserId,
    UR.DisplayName,
    UR.Reputation,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(UB.Badges, 'No badges') AS BadgeList,
    UR.PostCount,
    UR.AnswerCount,
    UR.UpvotedAnswers,
    UR.AvgPostScore,
    CASE 
        WHEN UR.LastPostDate IS NOT NULL AND UR.LastPostDate < NOW() - INTERVAL '1 year' THEN 'Inactive'
        ELSE 'Active'
    END AS ActivityStatus,
    PT.TagName,
    PT.TotalUpvotes,
    PT.TotalDownvotes
FROM 
    UserReputation UR
LEFT JOIN 
    UserBadges UB ON UR.UserId = UB.UserId
LEFT JOIN 
    PopularTags PT ON PT.TotalUpvotes > UR.UpvotedAnswers --only get top tags related to user's upvoted answers
WHERE 
    (UR.Reputation IS NULL OR UR.Reputation > 1000) -- obscure cases including NULL reputation 
    AND (UB.BadgeCount > 0 OR PT.TagName IS NOT NULL) -- ensuring user has badges or interacted with popular tags
ORDER BY 
    UR.Reputation DESC, 
    UR.LastPostDate DESC NULLS LAST
LIMIT 50;
