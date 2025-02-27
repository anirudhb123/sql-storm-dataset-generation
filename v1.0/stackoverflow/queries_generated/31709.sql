WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Starting from Questions

    UNION ALL
    
    SELECT 
        P.Id,
        P.Title,
        P.ParentId,
        R.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy R ON P.ParentId = R.PostId
    WHERE 
        P.PostTypeId = 2  -- Only consider Answers
),

UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.Score > 0 THEN P.Id END) AS UpvotedPosts,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        R.Tags,
        R.PostId,
        R.Level,
        R.Title
    FROM 
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            STRING_AGG(T.TagName, ', ') AS Tags
        FROM 
            Posts 
        CROSS JOIN LATERAL STRING_TO_ARRAY(Tags, ',') AS tag
        JOIN Tags T ON T.TagName = TRIM(BOTH '<>' FROM tag) 
        GROUP BY PostId
    ) R ON P.Id = R.PostId
    GROUP BY U.Id, U.DisplayName, R.Tags, R.PostId, R.Level, R.Title
),

VoteSummary AS (
    SELECT
        P.Id AS PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId = 6 THEN 1 END) AS CloseVotes
    FROM 
        Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id
)

SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.UpvotedPosts,
    U.TotalViews,
    R.Title,
    R.Level,
    V.UpVotes,
    V.DownVotes,
    V.CloseVotes
FROM 
    UserPostStats U
JOIN 
    RecursivePostHierarchy R ON U.PostId = R.PostId
JOIN 
    VoteSummary V ON R.PostId = V.PostId
WHERE 
    U.TotalPosts > 10 
    AND U.UpvotedPosts > 5 
    AND U.TotalViews > 1000
    AND R.Level < 3  -- Limit to a depth of 3 in the post hierarchy
ORDER BY 
    U.TotalViews DESC, U.DisplayName
LIMIT 100;
