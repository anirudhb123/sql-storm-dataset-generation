WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY COUNT(a.Id) DESC) AS TagRank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
        LEFT JOIN Comments c ON c.PostId = p.Id
        LEFT JOIN Votes v ON v.PostId = p.Id
        LEFT JOIN STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tags_array ON TRUE
        LEFT JOIN Tags t ON t.TagName = tags_array
    WHERE 
        p.PostTypeId = 1  -- Only consider Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'  -- Only posts from the last year
    GROUP BY 
        p.Id, u.DisplayName
),
TagStatistics AS (
    SELECT 
        TagList,
        COUNT(PostId) AS PostCount,
        SUM(AnswerCount) AS TotalAnswers,
        SUM(CommentCount) AS TotalComments,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes,
        AVG(EXTRACT(EPOCH FROM (NOW() - CreationDate))) / 3600 AS AvgHoursSinceCreation
    FROM 
        RankedPosts
    WHERE
        TagRank <= 5  -- Top 5 ranked posts for each tag
    GROUP BY 
        TagList
)
SELECT 
    TagList,
    PostCount,
    TotalAnswers,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes,
    AvgHoursSinceCreation,
    CASE 
        WHEN TotalUpVotes > TotalDownVotes THEN 'Popular'
        ELSE 'Less Popular'
    END AS PopularityStatus
FROM 
    TagStatistics
ORDER BY 
    TotalUpVotes DESC, PostCount DESC;
