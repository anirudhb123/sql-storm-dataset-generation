WITH 
-- CTE to gather the latest edit for each post, focusing on title and body changes
LatestEdits AS (
    SELECT 
        Ph.PostId, 
        MAX(Ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory Ph
    WHERE 
        Ph.PostHistoryTypeId IN (4, 5) -- Edit Title and Edit Body
    GROUP BY 
        Ph.PostId
),
PostEditDetails AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.Body, 
        L.LastEditDate,
        COALESCE(PH.Comment, '') AS LastComment
    FROM 
        Posts P
    JOIN 
        LatestEdits L ON P.Id = L.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.CreationDate = L.LastEditDate
),
-- Recursive CTE to fetch all related posts for each post through PostLinks
RecursivePostLinks AS (
    SELECT 
        PL.PostId, 
        PL.RelatedPostId
    FROM 
        PostLinks PL
    UNION ALL
    SELECT 
        PL.PostId, 
        PL.RelatedPostId
    FROM 
        PostLinks PL
    JOIN 
        RecursivePostLinks R ON PL.PostId = R.RelatedPostId
),
-- Final aggregation to analyze user engagement and post edit performance
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT E.PostId) AS PostsEdited,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostEditDetails E ON P.Id = E.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        U.Id
)
-- Main query to pull relevant data
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalComments,
    U.PostsEdited,
    U.TotalBounty,
    string_agg(DISTINCT T.TagName, ', ') AS TagsUsed
FROM 
    UserEngagement U
LEFT JOIN 
    Posts P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    string_to_array(P.Tags, ',') AS Tags ON TRUE
LEFT JOIN 
    Tags T ON T.TagName = Tags
GROUP BY 
    U.UserId, U.DisplayName, U.TotalPosts, U.TotalComments, U.PostsEdited, U.TotalBounty
ORDER BY 
    U.TotalPosts DESC, U.TotalComments DESC;
