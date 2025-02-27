-- Performance Benchmarking Query

WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),

TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.VoteCount,
    ua.UserId,
    ua.DisplayName AS AuthorDisplayName,
    ua.PostsCount AS AuthorPostsCount,
    ua.TotalUpVotes AS AuthorTotalUpVotes,
    ua.TotalDownVotes AS AuthorTotalDownVotes,
    tu.TagName,
    tu.PostCount AS TagPostCount
FROM 
    RecentPosts rp
JOIN 
    Users ua ON rp.PostId IN (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    TagUsage tu ON rp.Title LIKE '%' || tu.TagName || '%'
ORDER BY 
    rp.CreationDate DESC;
