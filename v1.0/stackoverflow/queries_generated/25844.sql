WITH ProcessedTags AS (
    SELECT 
        DISTINCT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
TagPostCounts AS (
    SELECT 
        Tag,
        COUNT(PostId) AS PostCount
    FROM 
        ProcessedTags
    JOIN 
        Posts ON Posts.Tags LIKE '%' || Tag || '%'
    GROUP BY 
        Tag
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS DownvotedPosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        UpvotedPosts,
        DownvotedPosts,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
    WHERE 
        PostCount > 0
)
SELECT 
    T.Tag,
    T.PostCount,
    U.DisplayName,
    U.Reputation,
    U.UpvotedPosts,
    U.DownvotedPosts,
    U.ReputationRank
FROM 
    TagPostCounts T
JOIN 
    TopUsers U ON T.PostCount = (
        SELECT 
            MAX(PostCount) 
        FROM 
            TopUsers 
        WHERE 
            UserId IN (SELECT OwnerUserId FROM Posts WHERE Tags LIKE '%' || T.Tag || '%')
    )
ORDER BY 
    T.PostCount DESC,
    U.Reputation DESC
LIMIT 10;
