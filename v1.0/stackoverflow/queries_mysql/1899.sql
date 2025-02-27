
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        @user_rank := @user_rank + 1 AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 9 
    CROSS JOIN (SELECT @user_rank := 0) AS r
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS TagPostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 10
),
RecentEdits AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        @edit_rank := IF(@prev_post = PH.PostId, @edit_rank + 1, 1) AS EditRank,
        @prev_post := PH.PostId
    FROM 
        PostHistory PH
    CROSS JOIN (SELECT @edit_rank := 0, @prev_post := NULL) AS r
    WHERE 
        PH.PostHistoryTypeId IN (4, 5) 
    ORDER BY 
        PH.PostId, PH.CreationDate DESC
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    P.Title,
    P.Tags,
    REPLACE(REPLACE(P.Body, '<br>', ' '), '</p>', '') AS CleanedBody,
    @latest_activity := IF(@prev_post2 = P.Id, @latest_activity + 1, 1) AS LatestActivity,
    @prev_post2 := P.Id,
    Tag.TagName,
    E.CreationDate AS LastEditDate,
    E.UserId AS LastEditedBy
FROM 
    UserStats U
JOIN 
    Posts P ON U.UserId = P.OwnerUserId
JOIN 
    PopularTags Tag ON P.Tags LIKE CONCAT('%', Tag.TagName, '%')
LEFT JOIN 
    RecentEdits E ON P.Id = E.PostId AND E.EditRank = 1
CROSS JOIN (SELECT @latest_activity := 0, @prev_post2 := NULL) AS r
WHERE 
    U.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND P.CreationDate >= CURDATE() - INTERVAL 30 DAY
    AND P.Body IS NOT NULL
ORDER BY 
    U.Reputation DESC, P.CreationDate DESC
LIMIT 100;
