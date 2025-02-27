WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    r.PostId,
    r.Title,
    r.Level,
    u.DisplayName AS Author,
    ur.TotalReputation,
    ps.UpVotes,
    ps.DownVotes,
    ps.CommentCount,
    ps.HistoryCount,
    CASE 
        WHEN ps.UpVotes > ps.DownVotes THEN 'Positive'
        WHEN ps.UpVotes < ps.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = r.PostId AND v.VoteTypeId = 6) AS CloseVoteCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = r.PostId AND v.VoteTypeId = 7) AS ReopenVoteCount
FROM 
    RecursivePostHierarchy r
JOIN 
    Posts p ON r.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
JOIN 
    PostVoteSummary ps ON p.Id = ps.PostId
WHERE 
    r.Level <= 3
ORDER BY 
    r.Level DESC, ur.TotalReputation DESC;
