WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'), 1) AS TagCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.TagCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserPostRank = 1 -- Select the most recent post for each user
        AND rp.TagCount > 0 -- Ensure there are tags
        AND rp.UpVotes - rp.DownVotes > 10 -- Only consider posts with a significant positive score
)
SELECT 
    p.Title,
    p.Body,
    p.TagCount,
    p.UpVotes,
    p.DownVotes,
    p.CommentCount
FROM 
    FilteredPosts p
ORDER BY 
    p.UpVotes DESC, p.CommentCount DESC -- Order by most upvotes, then most comments
LIMIT 10; -- Limit to the top 10 posts
