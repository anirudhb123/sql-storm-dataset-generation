WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.OwnerUserId,
        a.CreationDate,
        a.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        Posts q ON a.ParentId = q.Id
    WHERE 
        q.PostTypeId = 1 -- Questions
)
, PostVoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 2 OR VoteTypeId = 3 THEN 1 END) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistoryDetail AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        p.Title,
        RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS Rank
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) -- Close and reopen actions
)
SELECT 
    p.Title AS PostTitle,
    u.DisplayName AS OwnerName,
    Ph.CreationDate AS HistoryDate,
    Ph.Comment AS Reason,
    COALESCE(PVS.UpVotes, 0) AS UpVotes,
    COALESCE(PVS.DownVotes, 0) AS DownVotes,
    COALESCE(PVS.TotalVotes, 0) AS TotalVotes,
    RPH.Level AS PostLevel,
    (SELECT STRING_AGG(tag.TagName, ', ') 
     FROM Tags tag 
     WHERE tag.Id IN (SELECT UNNEST(string_to_array(Tags, '<>')::int[]))) AS RelatedTags
FROM 
    RecursivePostHierarchy RPH
INNER JOIN 
    Users u ON RPH.OwnerUserId = u.Id
LEFT JOIN 
    PostVoteSummary PVS ON RPH.PostId = PVS.PostId
LEFT JOIN 
    PostHistoryDetail Ph ON RPH.PostId = Ph.PostId AND Ph.Rank = 1
WHERE 
    RPH.CreationDate >= (NOW() - INTERVAL '1 year') -- Filter for posts in the last year
ORDER BY 
    RPH.Level, Ph.CreationDate DESC;
