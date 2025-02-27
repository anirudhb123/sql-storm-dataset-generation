WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Users U ON U.Id = p.OwnerUserId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, U.DisplayName
),
FilteredPosts AS (
    SELECT 
        Id, 
        Title, 
        CreationDate, 
        ViewCount,
        Score,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        PostStatistics
    WHERE 
        Score > 10 OR CommentCount > 5
),
RecentActivity AS (
    SELECT 
        p.Id,
        p.Title,
        p.LastActivityDate,
        DATEDIFF(CURRENT_TIMESTAMP, p.LastActivityDate) AS DaysSinceLastActivity
    FROM 
        Posts p
    WHERE 
        p.LastActivityDate IS NOT NULL
),
TopTags AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount
    FROM 
        (SELECT 
            unnest(string_to_array(Tags, '>')) AS TagName
         FROM 
            Posts) AS T
    GROUP BY 
        TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)

SELECT 
    fp.Id,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    ra.DaysSinceLastActivity,
    tt.TagName
FROM 
    FilteredPosts fp
LEFT JOIN 
    RecentActivity ra ON fp.Id = ra.Id
CROSS JOIN 
    TopTags tt
WHERE 
    ra.DaysSinceLastActivity < 30
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC;
