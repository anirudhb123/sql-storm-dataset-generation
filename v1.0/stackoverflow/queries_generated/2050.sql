WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId = 5 THEN 1 END) AS Favorites,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON V.PostId = P.Id
    GROUP BY U.Id, U.DisplayName
),
TopTags AS (
    SELECT 
        T.TagName,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON T.ExcerptPostId = P.Id OR T.WikiPostId = P.Id
    WHERE T.Count > 0
    GROUP BY T.TagName
    ORDER BY TotalViews DESC
    LIMIT 10
),
UserAttributes AS (
    SELECT 
        U.Id,
        U.Reputation,
        COALESCE(B.Class, 0) AS BadgeClass,
        B.Name AS BadgeName
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
),
RankedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.BadgeClass,
    T.TagName,
    P.Title AS RecentPostTitle,
    P.CreationDate AS PostCreationDate,
    P.Score AS PostScore,
    V.UpVotes,
    V.DownVotes,
    V.Favorites,
    R.PostRank,
    CASE 
        WHEN R.PostRank = 1 THEN 'Most Recent Post'
        ELSE NULL 
    END AS PostStatus
FROM UserVoteStats V
JOIN UserAttributes U ON V.UserId = U.Id
JOIN TopTags T ON T.PostCount > 0
JOIN RankedPosts R ON R.Id = (SELECT Id FROM Posts WHERE OwnerUserId = U.Id ORDER BY CreationDate DESC LIMIT 1)
WHERE U.Reputation > 100
ORDER BY U.Reputation DESC, V.TotalViews DESC;
