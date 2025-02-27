WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties 
    FROM 
        Users U 
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId 
    LEFT JOIN 
        Votes V ON P.Id = V.PostId 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount 
    FROM 
        Tags T 
    JOIN 
        Posts P ON T.Id = (SELECT unnest(string_to_array(P.Tags, ','))) 
    GROUP BY 
        T.TagName 
    ORDER BY 
        PostCount DESC 
    LIMIT 5
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS Author,
        PH.CreationDate AS LastEditDate
    FROM 
        Posts P 
    JOIN 
        Users U ON P.OwnerUserId = U.Id 
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId 
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days' 
    ORDER BY 
        P.CreationDate DESC 
    LIMIT 10
)
SELECT 
    US.DisplayName AS User,
    US.Reputation,
    US.QuestionCount,
    US.AnswerCount,
    US.TotalBounties,
    PT.TagName,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostDate,
    RP.LastEditDate
FROM 
    UserStatistics US
CROSS JOIN 
    PopularTags PT
LEFT JOIN 
    RecentPosts RP ON RP.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = US.UserId)
WHERE 
    US.Reputation > 1000
ORDER BY 
    US.Reputation DESC, PT.PostCount DESC;
