WITH RecursiveTagCounts AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    GROUP BY 
        Tags.TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount 
    FROM 
        RecursiveTagCounts 
    ORDER BY 
        PostCount DESC 
    LIMIT 10
),
UserEngagement AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Posts.Id) AS TotalPosts,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.Id, Users.DisplayName
),
PostHistories AS (
    SELECT 
        p.Title,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        p.Title
)
SELECT 
    tt.TagName,
    tt.PostCount,
    ue.DisplayName,
    ue.TotalPosts,
    ue.UpVotes,
    ue.DownVotes,
    ph.EditCount,
    ph.LastEditDate
FROM 
    TopTags tt
JOIN 
    UserEngagement ue ON ue.TotalPosts > 0
LEFT JOIN 
    Posts p ON p.Tags LIKE '%' || tt.TagName || '%'
LEFT JOIN 
    PostHistories ph ON ph.Title = p.Title
ORDER BY 
    tt.PostCount DESC, ue.UpVotes DESC;
