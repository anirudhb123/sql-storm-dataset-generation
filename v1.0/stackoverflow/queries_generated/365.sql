WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
), TopUsers AS (
    SELECT 
        UA.* 
    FROM 
        UserActivity UA
    WHERE 
        UA.ActivityRank <= 10
), PostScore AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        P.OwnerUserId,
        COALESCE(NULLIF(U.DisplayName, ''), 'Anonymous') AS Author,
        CASE 
            WHEN P.AwardedBadges > 0 THEN 'Badge Holder' 
            ELSE 'Regular' 
        END AS UserType,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRow
    FROM 
        Posts P
    LEFT JOIN 
        (
            SELECT 
                UserId, COUNT(*) AS AwardedBadges
            FROM 
                Badges
            GROUP BY 
                UserId
        ) B ON P.OwnerUserId = B.UserId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
)
SELECT 
    PU.DisplayName,
    COUNT(DISTINCT PS.Id) AS TotalPosts,
    SUM(PS.Score) AS TotalScore,
    AVG(PS.Score) AS AverageScore,
    MAX(PS.CreationDate) AS LastPostDate,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
FROM 
    TopUsers PU
JOIN 
    PostScore PS ON PU.UserId = PS.OwnerUserId
LEFT JOIN 
    UNNEST(string_to_array(PS.Tags, ',')) AS T(TagName) ON TRUE
WHERE 
    PS.PostRow = 1
GROUP BY 
    PU.DisplayName
ORDER BY 
    TotalScore DESC;
