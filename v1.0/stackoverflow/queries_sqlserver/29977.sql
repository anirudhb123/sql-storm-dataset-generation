
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY COUNT(v.Id) DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags
),

TagAggregation AS (
    SELECT 
        value AS Tag, 
        SUM(CommentCount) AS TotalComments,
        SUM(UpVotes) AS TotalUpvotes,
        SUM(DownVotes) AS TotalDownvotes
    FROM 
        RankedPosts
    CROSS APPLY STRING_SPLIT(Tags, ',')
    GROUP BY 
        value
),

FinalReport AS (
    SELECT 
        Tag, 
        TotalComments, 
        TotalUpvotes, 
        TotalDownvotes,
        RANK() OVER (ORDER BY TotalUpvotes DESC) AS UpvoteRank,
        RANK() OVER (ORDER BY TotalComments DESC) AS CommentRank
    FROM 
        TagAggregation
)

SELECT 
    Tag,
    TotalComments,
    TotalUpvotes,
    TotalDownvotes,
    UpvoteRank,
    CommentRank
FROM 
    FinalReport
WHERE 
    UpvoteRank <= 10 OR CommentRank <= 10
ORDER BY 
    UpvoteRank, CommentRank;
