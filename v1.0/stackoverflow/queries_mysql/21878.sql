
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (4, 10) THEN 1 ELSE 0 END), 0) AS FlaggedPosts,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS TotalPosts,
        @UserRank := @UserRank + 1 AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id AND V.PostId = P.Id,
        (SELECT @UserRank := 0) AS vars
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        PH.CreationDate,
        PH.Comment AS CloseReason
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10
),
RankedTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS TagUsageCount,
        @TagRank := @TagRank + 1 AS TagRank
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%'),
        (SELECT @TagRank := 0) AS vars
    GROUP BY 
        T.TagName
)
SELECT 
    UA.DisplayName,
    UA.UpVotes,
    UA.DownVotes,
    UA.TotalPosts,
    UA.UserRank,
    CP.PostId,
    CP.Title,
    CP.CloseReason,
    RT.TagName AS MostUsedTag,
    RT.TagUsageCount
FROM 
    UserActivity UA
LEFT JOIN 
    ClosedPosts CP ON UA.UserId = CP.OwnerUserId
LEFT JOIN 
    (SELECT TagName, TagUsageCount FROM RankedTags WHERE TagRank = 1) RT ON TRUE
WHERE 
    UA.UpVotes > UA.DownVotes
ORDER BY 
    UA.UserRank, UA.TotalPosts DESC;
