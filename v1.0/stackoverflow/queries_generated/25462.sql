WITH TagCount AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) as PostCount
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><')::int[])
    GROUP BY 
        Tags.TagName
),
TopUsers AS (
    SELECT 
        Users.DisplayName,
        SUM(COALESCE(Votes.VoteTypeId = 2, 0)) AS UpVotesCount,
        SUM(COALESCE(Votes.VoteTypeId = 3, 0)) AS DownVotesCount,
        COUNT(Posts.Id) AS PostsCount
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.DisplayName
    ORDER BY 
        UpVotesCount DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN c.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgeCount,
        ARRAY_AGG(DISTINCT ph.UserDisplayName) AS EditAuthors
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '2 years'
    GROUP BY 
        p.Id
    ORDER BY 
        p.ViewCount DESC
    LIMIT 20
)

SELECT 
    pcs.Id AS PostId,
    pcs.Title,
    pcs.ViewCount,
    pcs.CreationDate,
    pcs.CommentCount,
    pcs.BadgeCount,
    tu.DisplayName AS TopUser,
    tc.TagName,
    tc.PostCount
FROM 
    PostStatistics pcs
JOIN 
    TopUsers tu ON pcs.ViewCount = (SELECT MAX(p.ViewCount) FROM PostStatistics p)
JOIN 
    TagCount tc ON tc.PostCount = (SELECT MAX(c.PostCount) FROM TagCount c)
ORDER BY
    pcs.ViewCount DESC, 
    pcs.CreationDate DESC;
