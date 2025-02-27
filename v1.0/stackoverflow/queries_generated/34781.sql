WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL

    UNION ALL

    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy RPH ON P.ParentId = RPH.PostId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(V.value_count, 0)) AS TotalVotes,
        MAX(P.CreationDate) AS LastPost
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(VoteTypeId) AS value_count
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.TotalPosts,
        U.LastPost,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        UserStats U
),
PostsWithTagCount AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(T.Id) AS TagCount,
        MAX(P.Score) AS MaxScore
    FROM 
        Posts P
    LEFT JOIN 
        LATERAL unnest(string_to_array(P.Tags, ',')) AS Tag ON Tag IS NOT NULL
    LEFT JOIN 
        Tags T ON T.TagName = TRIM(BOTH ' ' FROM Tag)
    GROUP BY 
        P.Id
)

SELECT 
    U.DisplayName AS UserName,
    U.Reputation AS UserReputation,
    U.TotalPosts AS UserTotalPosts,
    P.Title AS PostTitle,
    PWC.TagCount AS TagsAssociated,
    PWC.MaxScore AS HighestPostScore,
    U.LastPost AS LastPostDate,
    PH.PostId AS RelatedPostId,
    PH.Title AS RelatedPostTitle,
    PH.CreationDate AS RelatedPostDate,
    ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.Reputation DESC) AS UserPosition 
FROM 
    TopUsers U
LEFT JOIN 
    PostsWithTagCount PWC ON U.UserId = PWC.PostId
LEFT JOIN 
    RecursivePostHierarchy PH ON PWC.PostId = PH.PostId
WHERE 
    PWC.TagCount > 3 
    AND U.TotalPosts > 5 
    AND U.Reputation IS NOT NULL
ORDER BY 
    U.UserRank, 
    PWC.MaxScore DESC;
