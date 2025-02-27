WITH TagStats AS (
    SELECT 
        tag.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.UpVoteCount, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVoteCount, 0)) AS TotalDownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM
        Tags AS tag
    LEFT JOIN 
        Posts AS p ON p.Tags LIKE CONCAT('%', tag.TagName, '%')
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) AS v ON p.Id = v.PostId
    LEFT JOIN 
        Comments AS c ON p.Id = c.PostId
    WHERE
        tag.Count > 100 -- Only include tags that are used in more than 100 posts
    GROUP BY 
        tag.TagName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerDisplayName,
        p.CreationDate,
        p.Title,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPosts
    FROM 
        Posts AS p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' -- Posts created in the last year
)

SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalUpVotes,
    ts.TotalDownVotes,
    ts.CommentCount,
    pa.OwnerDisplayName,
    pa.PostId,
    pa.Title,
    pa.ViewCount,
    pa.CreationDate
FROM 
    TagStats AS ts
JOIN 
    PostActivity AS pa ON pa.RecentPosts <= 5 -- Only show the 5 most recent posts per user
ORDER BY 
    ts.TotalUpVotes DESC, ts.PostCount DESC;
