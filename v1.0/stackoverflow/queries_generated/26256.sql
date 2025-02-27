WITH TagCount AS (
    SELECT 
        Tags.TagName, 
        COUNT(Posts.Id) AS PostCount
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><')::int[])
    GROUP BY 
        Tags.TagName
),
UserReputation AS (
    SELECT 
        Users.Id AS UserId, 
        Users.DisplayName, 
        Users.Reputation, 
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(COALESCE(Votes.VoteTypeId = 2, 0)) AS Upvotes, -- Only counting Upvotes
        SUM(COALESCE(Votes.VoteTypeId = 3, 0)) AS Downvotes -- Only counting Downvotes
    FROM 
        Users
    JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    WHERE 
        Users.Reputation > 100 -- Only considering users with more than 100 reputation
    GROUP BY 
        Users.Id, Users.DisplayName, Users.Reputation
),
ClosedPosts AS (
    SELECT 
        Posts.Id AS PostId, 
        Posts.Title, 
        PostHistory.UserDisplayName AS Editor,
        PostHistory.CreationDate AS ClosedDate
    FROM 
        Posts
    JOIN 
        PostHistory ON Posts.Id = PostHistory.PostId
    WHERE 
        PostHistory.PostHistoryTypeId = 10 -- Closed posts
)

SELECT 
    U.DisplayName AS UserDisplayName,
    U.Reputation,
    U.PostCount AS TotalPosts,
    U.Upvotes,
    U.Downvotes,
    COUNT(CP.PostId) AS ClosedPostsCount,
    STRING_AGG(DISTINCT TC.TagName, ', ') AS TagsUsed,
    AVG(U.Reputation) OVER() AS AvgUserReputation
FROM 
    UserReputation U
LEFT JOIN 
    ClosedPosts CP ON U.PostCount > 0 -- Joining only if they have posted something
LEFT JOIN 
    TagCount TC ON TC.PostCount > 0
GROUP BY 
    U.DisplayName, U.Reputation, U.PostCount, U.Upvotes, U.Downvotes
ORDER BY 
    U.Reputation DESC, 
    ClosedPostsCount DESC 
LIMIT 50;
