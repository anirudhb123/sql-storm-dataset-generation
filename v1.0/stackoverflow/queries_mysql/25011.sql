
WITH TopTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN (
        SELECT 
            @row := @row + 1 AS n 
        FROM 
            (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
             SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers, 
            (SELECT @row := 0) r 
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalQuestions,
        SUM(IFNULL(V.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 9 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        PH.CreationDate AS LastEditDate,
        PH.UserDisplayName AS LastEditor
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 30 DAY
    ORDER BY 
        P.CreationDate DESC
    LIMIT 20
)
SELECT 
    T.TagName,
    T.TagCount,
    UR.UserId,
    UR.DisplayName AS UserName,
    UR.Reputation,
    UR.TotalQuestions,
    UR.TotalBounties,
    RA.PostId,
    RA.Title AS PostTitle,
    RA.OwnerDisplayName,
    RA.CreationDate AS PostCreationDate,
    RA.Score AS PostScore,
    RA.ViewCount AS PostViewCount,
    RA.LastEditor,
    RA.LastEditDate
FROM 
    TopTags T
JOIN 
    UserReputation UR ON UR.TotalQuestions > 0 
JOIN 
    RecentActivity RA ON RA.Title LIKE CONCAT('%', T.TagName, '%') 
ORDER BY 
    T.TagCount DESC, UR.Reputation DESC, RA.Score DESC;
