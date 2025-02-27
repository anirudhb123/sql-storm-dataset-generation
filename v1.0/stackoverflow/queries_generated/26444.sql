WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS TagUsage
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
    GROUP BY 
        Tag
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id) AS PostCount,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id) AS BadgeCount
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000 -- Only users with significant reputation
),
ActivePostHistory AS (
    SELECT 
        PH.PostId,
        PT.Name AS PostType,
        COUNT(*) AS EditCount
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PHT.Id = PH.PostHistoryTypeId
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN 
        PostTypes PT ON PT.Id = P.PostTypeId
    WHERE 
        PHT.Name LIKE '%Edit%' -- Focus on edit actions
    GROUP BY 
        PH.PostId, PT.Name
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        COALESCE(E.EditCount, 0) AS EditCount,
        COALESCE(C.CommentCount, 0) AS CommentCount,
        COALESCE(V.VoteCount, 0) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) C ON C.PostId = P.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS VoteCount FROM Votes GROUP BY PostId) V ON V.PostId = P.Id
    LEFT JOIN 
        ActivePostHistory E ON E.PostId = P.Id
    WHERE 
        P.PostTypeId IN (1, 2) -- Questions and Answers
),
TopTags AS (
    SELECT 
        Tag, 
        TagUsage
    FROM 
        TagCounts
    ORDER BY 
        TagUsage DESC
    LIMIT 10
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.BadgeCount,
    P.Title,
    P.Score,
    P.EditCount,
    P.CommentCount,
    P.VoteCount,
    T.Tag,
    T.TagUsage
FROM 
    UserReputation U
JOIN 
    PostEngagement P ON P.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = U.UserId)
JOIN 
    TopTags T ON T.Tag = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><'))
WHERE 
    U.BadgeCount > 0 -- Only show users with badges
ORDER BY 
    U.Reputation DESC, P.Score DESC;
