WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting from questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        p.OwnerUserId,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON rp.Id = p.ParentId
    WHERE 
        p.PostTypeId = 2  -- Answers
),
VotingStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS TotalBadgePoints,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostWithVoting AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        u.DisplayName AS OwnerName,
        ur.TotalBadgePoints,
        ur.BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        VotingStats v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserReputation ur ON u.Id = ur.UserId
)
SELECT 
    rp.Id AS PostId,
    rp.Title AS QuestionTitle,
    rp.Score AS QuestionScore,
    rp.ViewCount AS QuestionViewCount,
    pw.CreationDate AS PostCreationDate,
    pw.UpVotes AS TotalUpVotes,
    pw.DownVotes AS TotalDownVotes,
    u.DisplayName AS OwnerName,
    pp.Level,
    ur.TotalBadgePoints,
    ur.BadgeCount
FROM 
    RecursivePosts rp
JOIN 
    PostWithVoting pw ON rp.Id = pw.PostId
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
ORDER BY 
    rp.Score DESC,
    pw.UpVotes DESC,
    pw.DownVotes ASC
LIMIT 100;
