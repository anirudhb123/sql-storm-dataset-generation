WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) as VersionNumber
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) -- Filtering only close and reopen actions
),
UserReputation AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class = 1)::INT, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::INT, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::INT, 0) AS BronzeBadges
    FROM 
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AverageBounty,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Only considering posts from the last year
    GROUP BY 
        p.Id
)
SELECT 
    p.Title,
    p.CreationDate AS PostCreationDate,
    ph.PostHistoryTypeId,
    ph.CreationDate AS HistoryDate,
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    ps.CommentCount,
    ps.AverageBounty,
    ps.UpVotes,
    ps.DownVotes
FROM 
    RecursivePostHistory ph
    JOIN Posts p ON p.Id = ph.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN UserReputation up ON u.Id = up.Id
    LEFT JOIN PostStatistics ps ON p.Id = ps.PostId
WHERE 
    ph.VersionNumber = 1 AND 
    (ph.PostHistoryTypeId = 10 OR ph.PostHistoryTypeId = 11) 
ORDER BY 
    p.CreationDate DESC, 
    ph.CreationDate DESC
LIMIT 50;

This SQL query performs an elaborate analysis of post histories regarding closure and reopening actions while also pulling in user reputation information and post statistics. It incorporates Common Table Expressions (CTEs), joins, filtering, and aggregates to present a comprehensive view of the activity around posts regarding their closure status. It includes obfuscation for posts closed in the last year and ranks user badges.
