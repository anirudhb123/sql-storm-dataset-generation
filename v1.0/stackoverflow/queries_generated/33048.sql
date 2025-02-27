WITH RecursiveUserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        U.CreationDate,
        COALESCE((
            SELECT COUNT(*) 
            FROM Posts P 
            WHERE P.OwnerUserId = U.Id 
            AND P.CreationDate >= NOW() - INTERVAL '1 year'
        ), 0) AS PostsLastYear,
        COALESCE((
            SELECT COUNT(*) 
            FROM Comments C 
            WHERE C.UserId = U.Id 
            AND C.CreationDate >= NOW() - INTERVAL '1 year'
        ), 0) AS CommentsLastYear
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
    UNION ALL
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        U.CreationDate,
        COALESCE((
            SELECT COUNT(*) 
            FROM Posts P 
            WHERE P.OwnerUserId = U.Id 
            AND P.CreationDate >= NOW() - INTERVAL '1 year'
        ), 0) + R.PostsLastYear,
        COALESCE((
            SELECT COUNT(*) 
            FROM Comments C 
            WHERE C.UserId = U.Id 
            AND C.CreationDate >= NOW() - INTERVAL '1 year'
        ), 0) + R.CommentsLastYear
    FROM 
        Users U
    JOIN 
        RecursiveUserStats R ON U.Id < R.UserId
)
, UserActivity AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Views,
        UpVotes,
        DownVotes,
        PostsLastYear,
        CommentsLastYear,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        RecursiveUserStats
)
SELECT 
    UA.DisplayName,
    UA.Reputation,
    UA.Views,
    UA.UpVotes,
    UA.DownVotes,
    UA.PostsLastYear,
    UA.CommentsLastYear,
    CASE 
        WHEN UA.PostsLastYear > 10 THEN 'Active Contributor'
        WHEN UA.CommentsLastYear > 15 THEN 'Commenting Specialist'
        ELSE 'Regular User'
    END AS UserType
FROM 
    UserActivity UA
WHERE 
    UA.ReputationRank <= 50
ORDER BY 
    UA.Reputation DESC;

-- Performing a complex join to get the details of posts closed with specific reasons and 
-- integrating user statistics

SELECT 
    P.Title,
    U.DisplayName,
    P.CreationDate,
    P.LastActivityDate,
    CH.Comment,
    CH.CreationDate AS CloseDate,
    CASE 
        WHEN CH.Comment IS NULL THEN 'Not Closed'
        ELSE 'Closed'
    END AS PostStatus
FROM 
    Posts P
LEFT JOIN 
    (SELECT DISTINCT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.Comment
     FROM 
        PostHistory PH
     WHERE 
        PH.PostHistoryTypeId = 10 
        AND PH.Comment IN (SELECT Name FROM CloseReasonTypes WHERE Id IN (1, 2, 3))
    ) CH ON P.Id = CH.PostId
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.CreationDate >= NOW() - INTERVAL '1 year'
ORDER BY 
    P.LastActivityDate DESC
LIMIT 100;

-- Using string manipulation and aggregation to group tags from the posts

SELECT 
    T.TagName,
    COUNT(P.Id) AS PostCount,
    STRING_AGG(DISTINCT P.Title, ', ') AS PostTitles
FROM 
    Tags T
JOIN 
    Posts P ON P.Tags ILIKE '%' || T.TagName || '%'
WHERE 
    P.CreationDate >= NOW() - INTERVAL '6 months'
GROUP BY 
    T.TagName
HAVING 
    COUNT(P.Id) > 5
ORDER BY 
    PostCount DESC;
