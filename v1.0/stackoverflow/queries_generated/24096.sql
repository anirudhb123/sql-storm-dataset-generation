WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 -- BountyStart
    GROUP BY U.Id, U.DisplayName
),
PopularTopics AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(Tags, '><')) AS Tag,
        COUNT(P.Id) AS TagCount
    FROM Posts P
    WHERE P.PostTypeId = 1
    GROUP BY UNNEST(STRING_TO_ARRAY(Tags, '><'))
    ORDER BY TagCount DESC
    LIMIT 10
),
RecentPostEdits AS (
    SELECT 
        PH.PostId,
        PH.UserDisplayName,
        PH.CreationDate,
        PH.Comment,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS EditVersion
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
)
SELECT 
    U.DisplayName AS Editor,
    COALESCE(PH.UserDisplayName, 'System') AS LastEditedBy,
    posts.Title,
    posts.ViewCount,
    UserStats.TotalPosts,
    UserStats.TotalQuestions,
    UserStats.TotalAnswers,
    UserStats.TotalBounty,
    Popular.Tag,
    Popular.TagCount,
    Recent.EditVersion,
    CASE
        WHEN PH.CreationDate IS NULL THEN 'Never Edited'
        ELSE TO_CHAR(PH.CreationDate, 'YYYY-MM-DD HH24:MI:SS')
    END AS LastEditDate
FROM Posts posts
LEFT JOIN UserStatistics UserStats ON posts.OwnerUserId = UserStats.UserId
LEFT JOIN PopularTopics Popular ON posts.Id = Popular.Tag
LEFT JOIN RecentPostEdits PH ON posts.Id = PH.PostId AND PH.EditVersion = 1
WHERE 
    UserStats.TotalPosts > 5 
    OR (EXISTS (SELECT 1 FROM Votes V WHERE V.PostId = posts.Id AND V.VoteTypeId = 2) AND UserStats.TotalQuestions > 2)
    OR (posts.ViewCount > 1000 AND PH.UserId IS NOT NULL)
ORDER BY posts.ViewCount DESC, UserStats.TotalPosts DESC;
