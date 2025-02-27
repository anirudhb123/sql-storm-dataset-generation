WITH RankedUsers AS (
    SELECT 
        U.Id, 
        U.DisplayName, 
        U.Reputation, 
        U.CreationDate,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.OwnerUserId, 
        P.CreationDate, 
        P.Title,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.OwnerUserId, P.CreationDate, P.Title
),
PostSummaries AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        U.DisplayName,
        U.Reputation,
        RP.CommentCount,
        RANK() OVER (PARTITION BY RP.OwnerUserId ORDER BY RP.CreationDate DESC) AS PostRank
    FROM RecentPosts RP
    JOIN Users U ON RP.OwnerUserId = U.Id
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON P.Tags ILIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
    HAVING COUNT(P.Id) > 10
),
ExtendedPostData AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CommentCount,
        PT.Name AS PostType,
        COALESCE(PTW.VoteCount, 0) AS TotalVotes,
        P.CreatedDate
    FROM PostSummaries PS
    JOIN PostTypes PT ON PS.PostId = PT.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) PTW ON PS.PostId = PTW.PostId
)
SELECT 
    EP.Title,
    EP.CommentCount,
    U.DisplayName,
    U.Reputation,
    T.TagName,
    EP.TotalVotes,
    CASE WHEN EP.TotalVotes > 10 THEN 'Popular' ELSE 'Regular' END AS PostCategory,
    EXTRACT(YEAR FROM EP.CreatedDate) AS PostYear
FROM ExtendedPostData EP
JOIN RankedUsers U ON EP.OwnerUserId = U.Id
LEFT JOIN PopularTags T ON EP.Title ILIKE '%' || T.TagName || '%'
WHERE EP.PostRank = 1
ORDER BY U.Reputation DESC, EP.CommentCount DESC;
