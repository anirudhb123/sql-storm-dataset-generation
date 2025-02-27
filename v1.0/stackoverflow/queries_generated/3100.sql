WITH UserActivity AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostsCount,
        SUM(COALESCE(Votes.VoteTypeId = 2, 0)) AS UpVotes,
        SUM(COALESCE(Votes.VoteTypeId = 3, 0)) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT Posts.Id) DESC) AS ActivityRank
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    WHERE 
        Users.Reputation > 1000
    GROUP BY 
        Users.Id, Users.DisplayName
),

ClosedPosts AS (
    SELECT 
        Posts.Id,
        Posts.Title,
        COUNT(PostHistory.Id) AS CloseActions,
        MAX(PostHistory.CreationDate) AS LastClosed
    FROM 
        Posts
    INNER JOIN 
        PostHistory ON Posts.Id = PostHistory.PostId 
    WHERE 
        PostHistory.PostHistoryTypeId = 10
    GROUP BY 
        Posts.Id, Posts.Title
)

SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.PostsCount,
    UA.UpVotes,
    UA.DownVotes,
    UA.ActivityRank,
    COALESCE(CP.CloseActions, 0) AS TotalCloseActions,
    CP.LastClosed
FROM 
    UserActivity UA
LEFT JOIN 
    ClosedPosts CP ON UA.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = CP.Id)
WHERE 
    UA.ActivityRank <= 10
ORDER BY 
    UA.ActivityRank;

WITH TagUsage AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostsCount,
        SUM(CASE WHEN Posts.ViewCount > 1000 THEN 1 ELSE 0 END) AS PopularPostsCount
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, '><')::int[])
    GROUP BY 
        Tags.TagName
)

SELECT 
    TU.TagName,
    TU.PostsCount,
    TU.PopularPostsCount,
    CASE 
        WHEN TU.PopularPostsCount > 5 THEN 'Frequent'
        WHEN TU.PopularPostsCount BETWEEN 2 AND 5 THEN 'Moderate'
        ELSE 'Rare'
    END AS Popularity
FROM 
    TagUsage TU
WHERE 
    TU.PostsCount > 10
ORDER BY 
    TU.PostsCount DESC;
