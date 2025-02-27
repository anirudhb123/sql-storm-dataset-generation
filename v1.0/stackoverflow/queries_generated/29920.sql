WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'UpMod') AS UpvoteCount,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'DownMod') AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC, p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount,
        (rp.UpvoteCount - rp.DownvoteCount) AS NetVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserPostRank = 1 -- Only the top-ranked post per user
    ORDER BY 
        NetVotes DESC NULLS LAST, -- Order by net votes, consider NULLs last
        rp.CreationDate DESC -- In case of ties, recent posts first
    LIMIT 10 -- Top 10 posts
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.CommentCount,
    pp.UpvoteCount,
    pp.DownvoteCount,
    pp.NetVotes,
    STRING_AGG(t.TagName, ', ') AS TagList
FROM 
    PopularPosts pp
LEFT JOIN 
    Posts p ON pp.PostId = p.Id
LEFT JOIN 
    STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_array ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag_array
GROUP BY 
    pp.PostId, pp.Title, pp.CreationDate, pp.CommentCount, pp.UpvoteCount, pp.DownvoteCount, pp.NetVotes
ORDER BY 
    pp.NetVotes DESC, pp.CreationDate DESC; -- Final order
