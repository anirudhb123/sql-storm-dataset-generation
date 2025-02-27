WITH RecursivePostCTE AS (
    -- Start with the root questions (PostTypeId = 1)
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        0 AS Level,
        p.AcceptedAnswerId,
        CAST(p.Title AS VARCHAR(MAX)) AS Path
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1

    UNION ALL

    -- Recursively find answers to each question
    SELECT 
        p2.Id AS PostId,
        p2.Title,
        p2.CreationDate,
        p2.Score,
        p2.ViewCount,
        p2.OwnerUserId,
        cte.Level + 1 AS Level,
        p2.AcceptedAnswerId,
        CAST(cte.Path + ' -> ' + p2.Title AS VARCHAR(MAX))
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostCTE cte ON p2.ParentId = cte.PostId
    WHERE 
        p2.PostTypeId = 2 -- Only answers

),
PostVoteStats AS (
    -- Get statistics for votes on each post
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
LatestBadges AS (
    -- Find latest badge received by each user
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        b.Date AS BadgeDate,
        ROW_NUMBER() OVER (PARTITION BY b.UserId ORDER BY b.Date DESC) AS rn
    FROM 
        Badges b
),
UserDetails AS (
    -- Bring in user details
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(lb.BadgeName, 'No Badge') AS LatestBadge
    FROM 
        Users u
    LEFT JOIN 
        LatestBadges lb ON u.Id = lb.UserId AND lb.rn = 1
)

SELECT 
    cte.PostId,
    cte.Title,
    cte.CreationDate,
    cte.Level,
    COALESCE(v. UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes,
    ud.DisplayName AS UserOwner,
    ud.Reputation AS UserReputation,
    CASE 
        WHEN cte.AcceptedAnswerId IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS HasAcceptedAnswer,
    Path
FROM 
    RecursivePostCTE cte
LEFT JOIN 
    PostVoteStats v ON cte.PostId = v.PostId
JOIN 
    UserDetails ud ON cte.OwnerUserId = ud.UserId
ORDER BY 
    cte.CreationDate DESC;

-- Optionally, combine with a UNION to compile closed questions
UNION 

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    NULL AS Level,
    0 AS UpVotes,
    0 AS DownVotes,
    ud.DisplayName AS UserOwner,
    ud.Reputation AS UserReputation,
    'No' AS HasAcceptedAnswer,
    'Closed Question' AS Path
FROM 
    Posts p
JOIN 
    UserDetails ud ON p.OwnerUserId = ud.UserId
WHERE 
    p.PostTypeId = 1 AND EXISTS (SELECT 1 FROM PostHistory ph WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId = 10) -- Closed questions
ORDER BY 
    CreationDate DESC;
