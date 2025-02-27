WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,  -- Count upvotes
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes, -- Count downvotes
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Tags
),
TopRanked AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 -- Get the latest post per tag
),
TagStatistics AS (
    SELECT 
        STRING_AGG(t.TagName, ', ') AS TagsList,
        COUNT(tp.PostId) AS TotalPosts,
        SUM(tp.CommentCount) AS TotalComments,
        SUM(tp.UpVotes) AS TotalUpVotes,
        SUM(tp.DownVotes) AS TotalDownVotes
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])  -- Use positive integer array for tags
    LEFT JOIN 
        TopRanked tp ON p.Id = tp.PostId
    GROUP BY 
        t.Id
)
SELECT 
    ts.TagsList,
    ts.TotalPosts,
    ts.TotalComments,
    ts.TotalUpVotes,
    ts.TotalDownVotes,
    CASE 
        WHEN ts.TotalPosts > 0 THEN ts.TotalComments::float / ts.TotalPosts
        ELSE 0
    END AS AvgCommentsPerPost,
    CASE 
        WHEN ts.TotalPosts > 0 THEN ts.TotalUpVotes::float / ts.TotalPosts
        ELSE 0
    END AS AvgUpVotesPerPost,
    CASE 
        WHEN ts.TotalPosts > 0 THEN ts.TotalDownVotes::float / ts.TotalPosts
        ELSE 0
    END AS AvgDownVotesPerPost
FROM 
    TagStatistics ts
ORDER BY 
    ts.TotalPosts DESC;
