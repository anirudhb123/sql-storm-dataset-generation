WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        0 AS Level,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        CAST(NULL AS varchar(300)) AS ParsedTags
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1  -- Starting from Questions
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        rp.Level + 1,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        CAST(NULL AS varchar(300))
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE rp ON p.ParentId = rp.PostId
)
, TagAggregates AS (
    SELECT 
        rp.PostId,
        STRING_AGG(DISTINCT TRIM(SUBSTRING(tag, 2, LENGTH(tag) - 2)), ', ') AS TagsList,
        COUNT(rp.PostId) AS AnswersCount
    FROM 
        RecursivePostCTE rp
    CROSS JOIN 
        STRING_TO_ARRAY(rp.Tags, '>') AS tag
    GROUP BY 
        rp.PostId
)
, VotingStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(CASE WHEN VoteTypeId = 6 THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN VoteTypeId = 7 THEN 1 END) AS ReopenVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    q.PostId,
    q.Title,
    q.CreationDate,
    q.LastActivityDate,
    q.Score,
    q.ViewCount,
    ta.TagsList,
    ta.AnswersCount,
    vs.Upvotes,
    vs.Downvotes,
    vs.CloseVotes,
    vs.ReopenVotes,
    CASE 
        WHEN q.AcceptedAnswerId IS NOT NULL THEN 'Yes' 
        ELSE 'No'
    END AS HasAcceptedAnswer
FROM 
    RecursivePostCTE q
LEFT JOIN 
    TagAggregates ta ON q.PostId = ta.PostId
LEFT JOIN 
    VotingStats vs ON q.PostId = vs.PostId
WHERE 
    q.Level = 0 -- Only fetching questions
ORDER BY 
    q.Score DESC, 
    q.ViewCount DESC;
