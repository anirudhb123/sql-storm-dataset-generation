
WITH RecursiveTagHierarchy AS (
    SELECT 
        Id,
        TagName,
        COUNT(*) AS TagCount
    FROM 
        Tags
    GROUP BY 
        Id, TagName
    HAVING 
        COUNT(*) > 5
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT V.Id) AS TotalVotes,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(MAX(H.CreationDate), P.CreationDate) AS LastEdited
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory H ON P.Id = H.PostId AND H.PostHistoryTypeId IN (4, 5, 6) 
    WHERE 
        P.Score > 0
    GROUP BY 
        P.Id, P.Title, P.Score
)
SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.TotalVotes,
    COALESCE(RTH.TagName, 'N/A') AS PopularTag,
    PS.Title AS PostTitle,
    PS.Score,
    PS.CommentCount,
    RANK() OVER (PARTITION BY U.UserId ORDER BY PS.Score DESC) AS PostRank,
    DENSE_RANK() OVER (ORDER BY U.TotalVotes DESC) AS UserRank
FROM 
    UserActivity U
LEFT JOIN 
    PostStats PS ON PS.LastEdited = U.LastPostDate
LEFT JOIN 
    RecursiveTagHierarchy RTH ON RTH.Id IN (
        SELECT DISTINCT CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(PS.Title, ' ', numbers.n), ' ', -1) AS SIGNED)
        FROM (
            SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
            UNION ALL SELECT 9 UNION ALL SELECT 10
        ) numbers
        WHERE CHAR_LENGTH(PS.Title) - CHAR_LENGTH(REPLACE(PS.Title, ' ', '')) >= numbers.n - 1
    ) 
WHERE 
    U.TotalPosts > 0
ORDER BY 
    UserRank, PostRank;
