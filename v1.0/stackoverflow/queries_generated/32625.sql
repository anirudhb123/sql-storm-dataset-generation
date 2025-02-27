WITH RecursivePostCTE AS (
    SELECT 
        Id,
        Title,
        ViewCount,
        COALESCE(AcceptedAnswerId, 0) AS AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Questions only

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, 0),
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE rp ON p.ParentId = rp.Id
),

PostVoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
),

TagCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS TagCount
    FROM 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag
    CROSS JOIN 
        Posts
    GROUP BY 
        PostId
),

PostHistorySummary AS (
    SELECT 
        PostId,
        STRING_AGG(CONCAT(Name, ' (', CreationDate, ')'), ', ') AS HistoryDetails
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        PostId
)

SELECT 
    rp.Id AS QuestionId,
    rp.Title,
    rp.ViewCount,
    COALESCE(pvs.UpVoteCount, 0) AS TotalUpVotes,
    COALESCE(pvs.DownVoteCount, 0) AS TotalDownVotes,
    COALESCE(tc.TagCount, 0) AS TotalTags,
    phs.HistoryDetails,
    CASE 
        WHEN rp.AcceptedAnswerId = 0 THEN 'Not Accepted'
        ELSE 'Accepted'
    END AS AnswerAcceptanceStatus
FROM 
    RecursivePostCTE rp
LEFT JOIN 
    PostVoteSummary pvs ON rp.Id = pvs.PostId
LEFT JOIN 
    TagCounts tc ON rp.Id = tc.PostId
LEFT JOIN 
    PostHistorySummary phs ON rp.Id = phs.PostId
WHERE 
    rp.Level = 1 -- Only top-level questions
ORDER BY 
    rp.ViewCount DESC
LIMIT 100;
