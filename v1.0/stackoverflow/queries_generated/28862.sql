WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank,
        COUNT(c.Id) AS CommentCount,
        AVG(v.VoteTypeId = 2) AS AvgUpVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= DATEADD(year, -1, GETDATE())  -- Filter by last year
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.AvgUpVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank = 1  -- Get the latest post for each tag
    ORDER BY 
        rp.AvgUpVotes DESC  -- Order by average upvotes
    OFFSET 0 ROWS NEXT 10 ROWS ONLY  -- Limit to top 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.Tags,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.AvgUpVotes
FROM 
    FilteredPosts fp
JOIN 
    Tags t ON t.TagName = ANY(string_to_array(fp.Tags, '>'))  -- Joining with Tags based on tags
WHERE 
    t.Count > 100  -- Only include tags with more than 100 questions
ORDER BY 
    fp.CreationDate DESC;  -- Order by creation date of the post
