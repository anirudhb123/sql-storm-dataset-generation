WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCreated,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived,
        COUNT(DISTINCT b.Id) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
HighActivityUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostsCreated,
        UpvotesReceived,
        DownvotesReceived,
        BadgesCount,
        RANK() OVER (ORDER BY PostsCreated DESC) AS UserRank
    FROM 
        UserActivity
    WHERE 
        PostsCreated >= 10
),
TopTags AS (
    SELECT 
        tag.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags tag
    JOIN 
        Posts p ON tag.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        tag.TagName
    HAVING 
        COUNT(p.Id) > 5
),
UserRankedTags AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY u.UserId ORDER BY t.PostCount DESC) AS TagRank
    FROM 
        HighActivityUsers u
    JOIN 
        Posts p ON u.UserId = p.OwnerUserId
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
)
SELECT 
    u.DisplayName,
    ua.PostsCreated,
    COALESCE(ua.UpvotesReceived, 0) AS Upvotes,
    COALESCE(ua.DownvotesReceived, 0) AS Downvotes,
    GROUP_CONCAT(ut.TagName) FILTER (WHERE ut.TagRank <= 3) AS TopTags
FROM 
    UserActivity ua
LEFT JOIN 
    HighActivityUsers hu ON ua.UserId = hu.UserId
LEFT JOIN 
    UserRankedTags ut ON hu.UserId = ut.UserId
GROUP BY 
    u.DisplayName, ua.PostsCreated
HAVING 
    COUNT(ut.TagName) > 0
ORDER BY 
    ua.PostsCreated DESC, Upvotes DESC;

This SQL query encompasses a variety of complex constructs including Common Table Expressions (CTEs), window functions for ranking, multiple joins, and string manipulation for tag extraction. The outer join ensures we fetch users without posts and a correlated subquery is used for ranking tags per user, showcasing an elaborate SQL interaction that could be useful for performance benchmarking.
