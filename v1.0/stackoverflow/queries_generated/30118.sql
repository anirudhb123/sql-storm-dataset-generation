WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName, p.Score, p.Tags
),

RecentActivity AS (
    SELECT 
        PostId,
        MAX(LastActivityDate) AS LastActivity
    FROM 
        Posts
    GROUP BY 
        PostId
),

TopTags AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '>')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),

PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        ra.LastActivity,
        tt.TagName
    FROM 
        RankedPosts rp
    JOIN 
        RecentActivity ra ON rp.PostId = ra.PostId
    LEFT JOIN 
        TopTags tt ON rp.Tags ILIKE '%' || tt.TagName || '%'
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.LastActivity,
    COALESCE(tt.TagName, 'No Tags') AS TagName
FROM 
    PostDetails pd
LEFT JOIN 
    (SELECT DISTINCT PostId, TagName FROM TopTags) tt ON pd.PostId = tt.PostId
WHERE 
    pd.LastActivity > NOW() - INTERVAL '30 days'
ORDER BY 
    pd.UpVotes DESC, pd.CommentCount DESC
LIMIT 100;

This SQL query extracts detailed information about the top-performing questions from recent activity, including user information, vote counts, and tag details. The use of CTEs enables modular querying, allowing for efficient aggregation, filtering, and ranking of posts while utilizing window functions and string expressions for tag handling. The final result is limited to questions that have been active in the last 30 days, sorted by popularity.
