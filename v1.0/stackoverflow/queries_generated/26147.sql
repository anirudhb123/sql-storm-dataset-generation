WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 AND  -- Only consider Questions
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  -- Posts from the last year
    GROUP BY 
        p.Id, u.DisplayName
),
TagSummary AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '>')) AS Tag,
        COUNT(rp.PostId) AS PostCount,
        SUM(rp.CommentCount) AS TotalComments,
        SUM(rp.UpvoteCount) AS TotalUpvotes,
        SUM(rp.DownvoteCount) AS TotalDownvotes
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        TotalComments,
        TotalUpvotes,
        TotalDownvotes,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagSummary
)
SELECT 
    Tag,
    PostCount,
    TotalComments,
    TotalUpvotes,
    TotalDownvotes
FROM 
    TopTags
WHERE 
    TagRank <= 10  -- Get top 10 tags by Post Count
ORDER BY 
    TotalUpvotes DESC;  -- Order by most Upvotes
