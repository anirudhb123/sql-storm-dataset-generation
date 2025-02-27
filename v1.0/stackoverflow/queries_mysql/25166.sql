
WITH RankedTags AS (
    SELECT 
        Tags.TagName, 
        COUNT(*) AS TagCount 
    FROM 
        Posts 
    JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(Posts.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM 
         (SELECT @row := @row + 1 AS n 
          FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) 
          numbers, (SELECT @row := 0) r) numbers
         WHERE @row < (LENGTH(Posts.Tags) - LENGTH(REPLACE(Posts.Tags, '><', '')) + 1)
        ) AS Tags 
    ON true 
    WHERE 
        Posts.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR)
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
        GROUP_CONCAT(Tags.TagName) AS PostTags 
    FROM 
        Posts 
    JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(Posts.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM 
         (SELECT @row := @row + 1 AS n 
          FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) 
          numbers, (SELECT @row := 0) r) numbers
         WHERE @row < (LENGTH(Posts.Tags) - LENGTH(REPLACE(Posts.Tags, '><', '')) + 1)
        ) AS Tags 
    ON true 
    WHERE 
        Posts.PostTypeId = 1 
        AND Posts.Score > 10 
    GROUP BY 
        Posts.Id, Posts.Title, Posts.Score, Posts.ViewCount, Posts.CreationDate 
    ORDER BY 
        Posts.ViewCount DESC 
    LIMIT 10
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
        RankedTags ON FIND_IN_SET(RankedTags.TagName, SUBSTRING_INDEX(SUBSTRING_INDEX(Posts.Tags, '><', numbers.n), '><', -1)) 
    LEFT JOIN 
        UserEngagement ON UserEngagement.UserId = Posts.OwnerUserId 
    WHERE 
        Posts.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR)
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
LIMIT 15;
