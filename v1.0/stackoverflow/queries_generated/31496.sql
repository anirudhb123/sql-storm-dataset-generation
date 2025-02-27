WITH RecursiveTagCounts AS (
    SELECT 
        Tags.TagName,
        Posts.Id AS PostId,
        COUNT(Posts.Id) AS PostCount
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, '::int'))
    GROUP BY 
        Tags.TagName, Posts.Id
),
TopTags AS (
    SELECT 
        TagName,
        SUM(PostCount) AS TotalPosts
    FROM 
        RecursiveTagCounts
    GROUP BY 
        TagName
    ORDER BY 
        TotalPosts DESC
    LIMIT 10
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS AnswerCount,
        COALESCE(SUM(b.Class), 0) AS BadgeScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
UserRankings AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        AnswerCount,
        BadgeScore,
        ROW_NUMBER() OVER (ORDER BY (UpVotes - DownVotes) + BadgeScore DESC) AS Rank
    FROM 
        UserScores
)
SELECT 
    t.TagName,
    u.DisplayName,
    u.AnswerCount,
    u.UpVotes,
    u.DownVotes,
    u.BadgeScore,
    u.Rank
FROM 
    TopTags AS t
JOIN 
    Posts p ON t.TagName = ANY(string_to_array(p.Tags, '::text'))
JOIN 
    Users AS u ON p.OwnerUserId = u.Id
JOIN 
    UserRankings AS ur ON u.Id = ur.UserId
WHERE 
    ur.Rank <= 5
ORDER BY 
    t.TotalPosts DESC, 
    ur.Rank;

