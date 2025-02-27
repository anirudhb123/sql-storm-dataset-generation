WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
)

, PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)

, UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    ph.PostId,
    ph.Title AS QuestionTitle,
    COALESCE(v.UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes,
    COALESCE(bb.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(bb.BadgeNames, 'No Badges') AS UserBadges,
    r.Level AS QuestionLevel
FROM 
    RecursivePostHierarchy ph
LEFT JOIN 
    PostVoteCounts v ON ph.PostId = v.PostId
LEFT JOIN 
    Users u ON ph.PostId = u.Id
LEFT JOIN 
    UserBadges bb ON u.Id = bb.UserId
WHERE 
    ph.Level = 1  -- Only fetching the top-level questions
AND 
    EXISTS (SELECT 1 FROM Posts p WHERE p.Id = ph.PostId AND p.AcceptedAnswerId IS NOT NULL)
ORDER BY 
    v.UpVotes DESC, 
    ph.Title ASC;

WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
)

SELECT 
    p.Title,
    p.CreationDate AS PostCreationDate,
    uph.UpVoteCount,
    RANK() OVER (ORDER BY p.CreationDate DESC) AS PostRank
FROM 
    Posts p
LEFT JOIN 
    (
        SELECT 
            PostId,
            COUNT(*) AS UpVoteCount
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 2
        GROUP BY 
            PostId
    ) uph ON p.Id = uph.PostId
WHERE 
    p.PostTypeId IN (1, 2) -- Questions and Answers
ORDER BY 
    PostRank, 
    p.CreationDate DESC;
