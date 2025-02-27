
WITH TagFrequency AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag, 
        TagCount
    FROM 
        TagFrequency
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCount,
        COUNT(DISTINCT C.Id) AS CommentsCount,
        SUM(IFNULL(V.BountyAmount, 0)) AS TotalBounty,
        SUM(IF(V.VoteTypeId = 2, 1, 0)) AS UpVotes,
        SUM(IF(V.VoteTypeId = 3, 1, 0)) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    A.UserId,
    A.DisplayName,
    A.PostsCount,
    A.CommentsCount,
    A.TotalBounty,
    A.UpVotes,
    A.DownVotes,
    T.Tag,
    T.TagCount
FROM 
    UserActivity A
CROSS JOIN 
    TopTags T
WHERE 
    A.PostsCount > 5
ORDER BY 
    A.PostsCount DESC, 
    T.TagCount DESC;
