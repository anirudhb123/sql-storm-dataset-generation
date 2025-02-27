WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body, 
        p.Tags, 
        u.DisplayName AS OwnerDisplayName, 
        COUNT(a.Id) AS AnswerCount, 
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpvoteCount, 
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        Tags, 
        OwnerDisplayName,
        AnswerCount, 
        UpvoteCount, 
        DownvoteCount,
        (UpvoteCount - DownvoteCount) AS NetVoteCount
    FROM 
        RankedPosts
    WHERE 
        rn = 1  -- Get the latest post information
),
TagStatistics AS (
    SELECT 
        UNNEST(string_to_array(Tags, ',')) AS Tag, 
        COUNT(*) AS PostCount 
    FROM 
        FilteredPosts
    GROUP BY 
        Tag
),
RankedTags AS (
    SELECT 
        Tag, 
        PostCount, 
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStatistics
)

SELECT 
    fp.PostId, 
    fp.Title,
    fp.Body,
    fp.OwnerDisplayName, 
    fp.AnswerCount, 
    fp.UpvoteCount,
    fp.DownvoteCount,
    fp.NetVoteCount,
    rt.Tag,
    rt.PostCount 
FROM 
    FilteredPosts fp
JOIN 
    RankedTags rt ON rt.Rank <= 10  -- Limit to top 10 tags
ORDER BY 
    fp.NetVoteCount DESC, 
    fp.AnswerCount DESC;
