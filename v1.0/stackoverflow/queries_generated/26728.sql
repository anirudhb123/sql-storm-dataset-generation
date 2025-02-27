WITH TagStats AS (
    SELECT 
        tag.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopContributors
    FROM 
        Tags tag
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || tag.TagName || '%'
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        tag.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        CommentCount,
        UpVotes,
        DownVotes,
        BadgeCount,
        TopContributors,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStats
)
SELECT 
    t.TagName,
    t.PostCount,
    t.CommentCount,
    t.UpVotes,
    t.DownVotes,
    t.BadgeCount,
    t.TopContributors
FROM 
    TopTags t
WHERE 
    t.Rank <= 10
ORDER BY 
    t.PostCount DESC;
