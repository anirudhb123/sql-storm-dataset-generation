WITH PostTagCounts AS (
    SELECT 
        Posts.Id AS PostId,
        COUNT(DISTINCT Tags.TagName) AS TagCount
    FROM 
        Posts
    JOIN 
        Tags ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    GROUP BY 
        Posts.Id
),
UserEngagement AS (
    SELECT 
        Users.Id AS UserId,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Comments.Score) AS TotalCommentScore,
        SUM(Votes.VoteTypeId = 2) AS UpvotesReceived, -- Filter for Upvotes
        SUM(Votes.VoteTypeId = 3) AS DownvotesReceived -- Filter for Downvotes
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Comments ON Comments.UserId = Users.Id
    LEFT JOIN 
        Votes ON Votes.UserId = Users.Id
    GROUP BY 
        Users.Id
),
PostHistoryAggregation AS (
    SELECT 
        PostId,
        COUNT(*) AS EditCount,
        MAX(CreationDate) AS LastEditDate
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        PostId
),
UserPostStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UP.PostCount, 0) AS TotalPosts,
        COALESCE(PH.EditCount, 0) AS TotalEdits,
        COALESCE(PH.LastEditDate, '1970-01-01') AS LastEditDate,
        COALESCE(PTC.TagCount, 0) AS TotalTags
    FROM 
        Users U
    LEFT JOIN 
        UserEngagement UP ON U.Id = UP.UserId
    LEFT JOIN 
        PostHistoryAggregation PH ON PH.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.Id)
    LEFT JOIN 
        PostTagCounts PTC ON PTC.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.Id)
)
SELECT 
    USER.DisplayName,
    USER.Reputation,
    STATS.TotalPosts,
    STATS.TotalEdits,
    STATS.LastEditDate,
    STATS.TotalTags,
    ENG.TotalCommentScore,
    ENG.UpvotesReceived,
    ENG.DownvotesReceived
FROM 
    UserPostStatistics STATS
JOIN 
    UserEngagement ENG ON STATS.UserId = ENG.UserId
ORDER BY 
    STATS.TotalPosts DESC, STATS.Reputation DESC
LIMIT 10;
