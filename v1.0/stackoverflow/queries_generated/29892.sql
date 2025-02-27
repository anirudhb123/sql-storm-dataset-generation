WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- counting only Upvotes and Downvotes
    LEFT JOIN 
        LATERAL (SELECT * FROM unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName)) AS t
    WHERE 
        p.PostTypeId = 1 -- considering only Questions
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.CommentCount > 10 THEN 'High Comment Engagement'
            WHEN rp.VoteCount > 20 THEN 'High Vote Count Engagement'
            ELSE 'Normal Engagement'
        END AS EngagementLevel
    FROM 
        RankedPosts rp
    WHERE 
        rp.LastActivityDate > NOW() - INTERVAL '30 days' -- posts from the last 30 days
)
SELECT 
    f.Owner,
    COUNT(f.PostId) AS PostCount,
    AVG(EXTRACT(EPOCH FROM f.LastActivityDate - f.CreationDate) / 3600) AS AvgPostDurationHours,
    STRING_AGG(DISTINCT f.Tags) AS AllTags,
    COUNT(DISTINCT CASE WHEN f.EngagementLevel = 'High Comment Engagement' THEN f.PostId END) AS HighCommentPosts,
    COUNT(DISTINCT CASE WHEN f.EngagementLevel = 'High Vote Count Engagement' THEN f.PostId END) AS HighVotePosts
FROM 
    FilteredPosts f
GROUP BY 
    f.Owner
ORDER BY 
    PostCount DESC
LIMIT 10;
