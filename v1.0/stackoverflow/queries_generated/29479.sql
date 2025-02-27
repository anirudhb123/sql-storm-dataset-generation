WITH TagCounts AS (
    SELECT 
        TRIM(BOTH '<>' FROM UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><'))) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
),
UserActivity AS (
    SELECT 
        U.DisplayName AS UserName,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        COUNT(DISTINCT C.Id) AS CommentsMade,
        COUNT(DISTINCT B.Id) AS BadgesReceived,
        SUM(V.BountyAmount) AS TotalBounty,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserName,
        PostsCreated,
        CommentsMade,
        BadgesReceived,
        TotalBounty,
        UserRank
    FROM 
        UserActivity
    WHERE 
        UserRank <= 10
)
SELECT 
    T.TagName,
    T.PostCount,
    U.UserName,
    U.PostsCreated,
    U.CommentsMade,
    U.BadgesReceived,
    U.TotalBounty
FROM 
    TopTags T
JOIN 
    TopUsers U ON T.TagRank = U.UserRank
ORDER BY 
    T.PostCount DESC, U.PostsCreated DESC;
