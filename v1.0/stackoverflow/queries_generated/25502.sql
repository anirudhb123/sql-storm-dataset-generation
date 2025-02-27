WITH TagCounts AS (
    SELECT 
        Tags.TagName, 
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        COUNT(DISTINCT CAST(Posts.OwnerUserId AS INT)) AS UniquePostOwners
    FROM 
        Tags 
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '>'::text))
    GROUP BY 
        Tags.TagName
),
UserActivity AS (
    SELECT 
        Users.Id AS UserId, 
        Users.DisplayName, 
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Votes.Id IS NOT NULL) AS VoteCount,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    WHERE 
        Users.Reputation > 100
    GROUP BY 
        Users.Id
),
PostMetrics AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate, 
        Posts.Body,
        Tags.TagName,
        COALESCE(PostHistory.Text, 'No History') AS LastEdit,
        COALESCE(PostHistory.CreationDate, '1900-01-01') AS LastEditDate
    FROM 
        Posts 
    LEFT JOIN 
        PostHistory ON Posts.Id = PostHistory.PostId
    LEFT JOIN 
        Tags ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '>'::text))
    WHERE 
        Posts.CreationDate >= NOW() - INTERVAL '1 year' 
        AND Posts.Score > 5
)
SELECT 
    tc.TagName,
    tc.PostCount,
    tc.TotalViews,
    tc.UniquePostOwners,
    ua.DisplayName,
    ua.PostCount AS UserPostCount,
    ua.VoteCount,
    ua.UpVotes,
    ua.DownVotes,
    pm.Title,
    pm.CreationDate,
    pm.LastEdit,
    pm.LastEditDate
FROM 
    TagCounts tc
JOIN 
    UserActivity ua ON ua.PostCount > 10
LEFT JOIN 
    PostMetrics pm ON pm.TagName = tc.TagName
ORDER BY 
    tc.TotalViews DESC, 
    ua.VoteCount DESC
LIMIT 50;
