WITH RecursivePostCTE AS (
    SELECT P.Id,
           P.ParentId,
           P.Title,
           P.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY P.ParentId ORDER BY P.CreationDate DESC) AS RN
    FROM Posts P
    WHERE P.PostTypeId = 2  -- Answers only
    UNION ALL
    SELECT P.Id,
           P.ParentId,
           P.Title,
           P.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY P.ParentId ORDER BY P.CreationDate DESC) AS RN
    FROM Posts P
    INNER JOIN RecursivePostCTE RP ON P.Id = RP.ParentId
)
SELECT U.Id AS UserId,
       U.DisplayName,
       U.Reputation,
       COUNT(DISTINCT P.Id) AS TotalPosts,
       COUNT(DISTINCT C.Id) AS TotalComments,
       SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
       SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
       MAX(P.CreationDate) AS LastPostDate,
       COUNT(DISTINCT B.Id) AS TotalBadges
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
LEFT JOIN Comments C ON P.Id = C.PostId
LEFT JOIN Votes V ON P.Id = V.PostId
LEFT JOIN Badges B ON U.Id = B.UserId
WHERE U.Reputation > (
        SELECT AVG(U2.Reputation)
        FROM Users U2
        WHERE U2.Reputation IS NOT NULL
    )
GROUP BY U.Id, U.DisplayName, U.Reputation
HAVING COUNT(DISTINCT P.Id) > 5
   AND AVG(U.Reputation) >= 1000
   AND MAX(P.CreationDate) >= '2023-01-01'
ORDER BY LastPostDate DESC;

-- Additional insights on post engagements
SELECT P.Id AS PostId,
       P.Title,
       P.ViewCount,
       P.AnswerCount,
       P.CommentCount,
       COALESCE(PostLinkCounts.LinkCount, 0) AS RelatedPostCount,
       LEAD(P.Score, 1, 0) OVER (ORDER BY P.CreationDate DESC) AS NextPostScore
FROM Posts P
LEFT JOIN (
    SELECT PL.PostId,
           COUNT(*) AS LinkCount
    FROM PostLinks PL
    GROUP BY PL.PostId
) PostLinkCounts ON P.Id = PostLinkCounts.PostId
WHERE P.CreationDate >= '2022-01-01'
ORDER BY P.ViewCount DESC
LIMIT 10;

-- Aggregate user performance analysis
SELECT U.Id AS UserId,
       U.DisplayName,
       COUNT(P.Id) AS TotalPosts,
       SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
       SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
       COUNT(DISTINCT B.Id) AS BadgeCount,
       AVG(U.Reputation) AS AvgReputation,
       CASE WHEN SUM(P.Score) IS NULL THEN 'No Score' ELSE 'Has Score' END AS PostScoreStatus
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 9 -- BountyClose votes
LEFT JOIN Badges B ON U.Id = B.UserId
GROUP BY U.Id, U.DisplayName
HAVING COUNT(P.Id) > 2
 ORDER BY TotalPosts DESC, TotalViews DESC;
