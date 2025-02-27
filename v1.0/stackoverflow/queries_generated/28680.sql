WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
), 

FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Tags,
        ViewCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 -- Top 5 posts for each tag
), 

AggregateStats AS (
    SELECT 
        Tags,
        COUNT(PostId) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM 
        FilteredPosts
    GROUP BY 
        Tags
)

SELECT 
    Tags,
    PostCount,
    TotalViews,
    TotalUpVotes,
    TotalDownVotes,
    ROUND(TotalUpVotes::numeric / NULLIF(PostCount, 0), 2) AS AvgUpVotesPerPost,
    ROUND(TotalDownVotes::numeric / NULLIF(PostCount, 0), 2) AS AvgDownVotesPerPost
FROM 
    AggregateStats 
ORDER BY 
    TotalViews DESC;

This SQL query benchmarks string processing on the Stack Overflow schema by performing the following steps:
1. Extracts relevant information from the `Posts`, `Users`, and `Votes` tables.
2. Ranks the posts based on their view counts for each tag.
3. Filters the top 5 posts per tag.
4. Aggregates statistics such as total views and votes per tag.
5. Outputs the final statistics, including average votes per post.

This way, it provides insights into the engagement of posts categorized by their tags.
