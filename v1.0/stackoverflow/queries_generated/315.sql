WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        PT.Name AS PostType,
        U.DisplayName AS OwnerName,
        COUNT(C.*) AS CommentCount
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
    WHERE P.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY P.Id, PT.Name, U.DisplayName
),
PopularTags AS (
    SELECT 
        T.TagName,
        T.Count,
        ROW_NUMBER() OVER (ORDER BY T.Count DESC) AS TagRank
    FROM Tags T
    WHERE T.Count > 100
)
SELECT 
    UR.DisplayName,
    UR.Reputation,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS PostDate,
    RP.PostType,
    COALESCE(PT.Name, 'N/A') AS ParentPostType,
    PT.CommentCount AS TotalComments,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = RP.PostId AND V.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = RP.PostId AND V.VoteTypeId = 3) AS DownVotes,
    (SELECT STRING_AGG(T.TagName, ', ') FROM Tags T WHERE T.ExcerptPostId = RP.PostId) AS AssociatedTags
FROM UserReputation UR
LEFT JOIN RecentPosts RP ON UR.UserId = RP.OwnerUserId
LEFT JOIN PopularTags PT ON PT.TagRank <= 5  -- Limit to the top 5 popular tags
WHERE UR.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY UR.Reputation DESC, RP.CreationDate DESC;
