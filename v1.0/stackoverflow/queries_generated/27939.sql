WITH TagCounts AS (
    SELECT 
        Tags.TagName AS Tag,
        COUNT(Posts.Id) AS PostCount,
        SUM(COALESCE(Votes.VoteTypeId = 2, 0)) AS UpvoteCount,
        SUM(COALESCE(Votes.VoteTypeId = 3, 0)) AS DownvoteCount
    FROM 
        Posts 
    INNER JOIN 
        unnest(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')) AS Tags ON TRUE
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Tags.TagName
),
PopularTags AS (
    SELECT 
        Tag,
        PostCount,
        UpvoteCount,
        DownvoteCount,
        (UpvoteCount - DownvoteCount) AS NetVotes
    FROM 
        TagCounts
    WHERE 
        PostCount > 5 -- Only consider tags with more than 5 posts
    ORDER BY 
        NetVotes DESC
    LIMIT 10
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT Posts.Id) AS PostsCreated,
        COUNT(DISTINCT Comments.Id) AS CommentsMade,
        SUM(Votes.UserId IS NOT NULL) AS VotesCast
    FROM 
        Users U
    LEFT JOIN 
        Posts ON U.Id = Posts.OwnerUserId
    LEFT JOIN 
        Comments ON U.Id = Comments.UserId
    LEFT JOIN 
        Votes ON U.Id = Votes.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
)
SELECT 
    UEng.DisplayName,
    UEng.Reputation,
    PT.Tag,
    PT.PostCount,
    PT.UpvoteCount,
    PT.DownvoteCount,
    PT.NetVotes
FROM 
    UserEngagement UEng
JOIN 
    PopularTags PT ON PT.NetVotes > UEng.Reputation  -- Join to consider user engagement vs popular tags
ORDER BY 
    UEng.Reputation DESC, PT.NetVotes DESC;
