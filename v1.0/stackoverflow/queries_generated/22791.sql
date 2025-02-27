WITH RecentActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName AS UserName,
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(PC.CommentCount, 0) AS TotalComments,
        P.ViewCount,
        RANK() OVER (PARTITION BY U.Id ORDER BY P.CreationDate DESC) AS RankByActivity
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        (SELECT 
             PostId, COUNT(*) AS CommentCount 
         FROM 
             Comments 
         GROUP BY 
             PostId) PC ON P.Id = PC.PostId
    WHERE 
        U.Reputation > 1000 -- Only consider users with reputation above 1000
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        PH.CreationDate AS ClosedDate,
        PH.Comment
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId 
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Closed or reopened posts
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        LATERAL (SELECT 
                      UNNEST(STRING_TO_ARRAY(P.Tags, '>')) AS TagName) T 
      ON TRUE -- Use LATERAL join to split tags
    GROUP BY 
        P.Id
)
SELECT 
    R.UserName,
    R.PostId,
    R.Title,
    R.CreationDate,
    R.TotalComments,
    R.ViewCount,
    COALESCE(CP.ClosedDate, 'Not Closed') AS PostStatus,
    COALESCE(CP.Comment, 'N/A') AS ClosureComment,
    PT.Tags,
    CASE 
        WHEN R.RankByActivity = 1 THEN 'Most Recent Activity'
        ELSE 'Older Activity' 
    END AS ActivityRank,
    COUNT(DISTINCT V.UserId) AS VoteCount,
    AVG(U.Reputation) AS AverageReputation
FROM 
    RecentActivity R
LEFT JOIN 
    ClosedPosts CP ON R.PostId = CP.PostId
JOIN 
    PostTags PT ON R.PostId = PT.PostId
LEFT JOIN 
    Votes V ON R.PostId = V.PostId
JOIN 
    Users U ON V.UserId = U.Id
GROUP BY 
    R.UserName, R.PostId, R.Title, R.CreationDate, R.TotalComments, 
    R.ViewCount, CP.ClosedDate, CP.Comment, PT.Tags, R.RankByActivity
HAVING 
    COUNT(DISTINCT V.UserId) > 5 -- Only include posts with more than 5 votes
ORDER BY 
    R.CreationDate DESC;
