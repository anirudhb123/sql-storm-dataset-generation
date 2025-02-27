
WITH RankedTags AS (
    SELECT 
        Tags.TagName, 
        COUNT(*) AS TagCount 
    FROM 
        Posts 
    CROSS APPLY (SELECT value AS TagName FROM STRING_SPLIT(SUBSTRING(Posts.Tags, 2, LEN(Posts.Tags) - 2), '><')) AS Tags 
    WHERE 
        Posts.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        Tags.TagName 
    HAVING 
        COUNT(*) > 5
),
PopularPosts AS (
    SELECT 
        Posts.Id, 
        Posts.Title, 
        Posts.Score, 
        Posts.ViewCount, 
        Posts.CreationDate, 
        STRING_AGG(Tags.TagName, ',') AS PostTags 
    FROM 
        Posts 
    CROSS APPLY (SELECT value AS TagName FROM STRING_SPLIT(SUBSTRING(Posts.Tags, 2, LEN(Posts.Tags) - 2), '><')) AS Tags 
    WHERE 
        Posts.PostTypeId = 1 
        AND Posts.Score > 10 
    GROUP BY 
        Posts.Id, Posts.Title, Posts.Score, Posts.ViewCount, Posts.CreationDate 
    ORDER BY 
        Posts.ViewCount DESC 
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
UserEngagement AS (
    SELECT 
        Users.Id AS UserId, 
        Users.DisplayName, 
        COUNT(Votes.Id) AS VoteCount, 
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
    FROM 
        Users 
    LEFT JOIN 
        Votes ON Users.Id = Votes.UserId 
    GROUP BY 
        Users.Id, Users.DisplayName 
    HAVING 
        COUNT(Votes.Id) > 0
),
PostInsights AS (
    SELECT 
        Posts.Id AS PostId, 
        Posts.Title, 
        Posts.ViewCount, 
        Users.DisplayName AS OwnerName, 
        COALESCE(RankedTags.TagCount, 0) AS Popularity, 
        COALESCE(UserEngagement.VoteCount, 0) AS UserVoteCount 
    FROM 
        Posts 
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id 
    LEFT JOIN 
        RankedTags ON RankedTags.TagName IN (SELECT value FROM STRING_SPLIT(Posts.Tags, '>')) 
    LEFT JOIN 
        UserEngagement ON UserEngagement.UserId = Posts.OwnerUserId 
    WHERE 
        Posts.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
)
SELECT 
    PostInsights.*, 
    PopularPosts.PostTags 
FROM 
    PostInsights 
LEFT JOIN 
    PopularPosts ON PostInsights.PostId = PopularPosts.Id 
ORDER BY 
    PostInsights.Popularity DESC, 
    PostInsights.UserVoteCount DESC 
OFFSET 0 ROWS FETCH NEXT 15 ROWS ONLY;
