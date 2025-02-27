WITH RecursivePostCTE AS (
    -- Recursive CTE to find all parent posts for answers
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.CreationDate,
        1 AS Level,
        CAST(p.Title AS VARCHAR(MAX)) AS FullTitle
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.CreationDate,
        cte.Level + 1,
        CAST(cte.FullTitle + ' > ' + p.Title AS VARCHAR(MAX)) AS FullTitle
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE cte ON p.ParentId = cte.Id
    WHERE 
        p.PostTypeId = 2 -- Answers only
),
VoteSummary AS (
    -- Generate a summary of votes per post
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadgeCount AS (
    -- Count badges per user
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        MAX(CreationDate) AS LastBadgeDate
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostHistoryInfo AS (
    -- Capture post history and types
    SELECT 
        ph.PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ph.PostHistoryTypeId,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.Id END) AS CloseReopenCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    GROUP BY 
        ph.PostId, p.Title, p.CreationDate, p.LastActivityDate, p.ViewCount, p.AnswerCount, p.CommentCount
)
SELECT 
    r.FullTitle,
    COALESCE(vs.UpVotes, 0) - COALESCE(vs.DownVotes, 0) AS NetVotes,
    COUNT(b.UserId) AS BadgeHolders,
    pvi.CloseReopenCount,
    pvi.LastEditDate,
    ur.Reputation AS UserReputation
FROM 
    RecursivePostCTE r
LEFT JOIN 
    VoteSummary vs ON vs.PostId = r.Id
LEFT JOIN 
    PostHistoryInfo pvi ON pvi.PostId = r.Id
LEFT JOIN 
    Users ur ON ur.Id = r.Id
LEFT JOIN 
    UserBadgeCount b ON b.UserId = ur.Id
WHERE 
    r.Level = 1 -- Only the top-level questions
GROUP BY 
    r.FullTitle, vs.UpVotes, vs.DownVotes, pvi.CloseReopenCount, pvi.LastEditDate, ur.Reputation
ORDER BY 
    NetVotes DESC, r.CreationDate DESC;
