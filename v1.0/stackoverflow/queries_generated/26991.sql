WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), 1) AS TagCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS UpVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, u.DisplayName
),
TagDistribution AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        FilteredPosts
    GROUP BY 
        Tag
),
MostCommentedPosts AS (
    SELECT 
        PostId,
        Title,
        CommentCount
    FROM 
        FilteredPosts
    ORDER BY 
        CommentCount DESC
    LIMIT 5
),
TopUpvotedPosts AS (
    SELECT 
        PostId,
        Title,
        UpVoteCount
    FROM 
        FilteredPosts
    ORDER BY 
        UpVoteCount DESC
    LIMIT 5
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalReputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.TagCount,
    tc.PostCount AS TagDistribution,
    mcp.CommentCount AS MostCommentedPost,
    tup.UpVoteCount AS TopUpvotedPost,
    ur.DisplayName AS UserDisplayName,
    ur.TotalReputation,
    ur.BadgeCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    TagDistribution tc ON tc.Tag = ANY (string_to_array(substring(fp.Tags, 2, length(fp.Tags)-2), '><'))
LEFT JOIN 
    MostCommentedPosts mcp ON mcp.PostId = fp.PostId
LEFT JOIN 
    TopUpvotedPosts tup ON tup.PostId = fp.PostId
LEFT JOIN 
    UserReputation ur ON ur.UserId = fp.OwnerUserId
ORDER BY 
    fp.CreationDate DESC;
