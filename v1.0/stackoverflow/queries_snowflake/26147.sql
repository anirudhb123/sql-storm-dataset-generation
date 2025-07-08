
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
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
        p.PostTypeId = 1 AND  
        p.CreationDate >= DATEADD(year, -1, '2024-10-01') 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, p.Tags
),
TagSummary AS (
    SELECT 
        TRIM(value) AS Tag,
        COUNT(rp.PostId) AS PostCount,
        SUM(rp.CommentCount) AS TotalComments,
        SUM(rp.UpvoteCount) AS TotalUpvotes,
        SUM(rp.DownvoteCount) AS TotalDownvotes
    FROM 
        RankedPosts rp,
        LATERAL FLATTEN(input => SPLIT(SUBSTR(rp.Tags, 2, LEN(rp.Tags) - 2), '>')) AS value
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
    TagRank <= 10  
ORDER BY 
    TotalUpvotes DESC;
