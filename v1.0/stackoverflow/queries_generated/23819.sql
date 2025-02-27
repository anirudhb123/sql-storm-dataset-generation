WITH UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  -- Questions and Answers
),
PostVoteInfo AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseActionCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY 
        ph.PostId
),
OverallStats AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        u.Reputation,
        COUNT(DISTINCT rp.Id) AS RecentPostsCount,
        COALESCE(pvi.UpVotes, 0) AS TotalUpVotes,
        COALESCE(pvi.DownVotes, 0) AS TotalDownVotes,
        COALESCE(cp.CloseActionCount, 0) AS CloseActionCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        RecentPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        PostVoteInfo pvi ON pvi.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
    LEFT JOIN 
        ClosedPosts cp ON cp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
    GROUP BY 
        u.Id, ub.BadgeCount, u.Reputation, pvi.UpVotes, pvi.DownVotes, cp.CloseActionCount
)
SELECT 
    o.UserId,
    o.BadgeCount,
    o.Reputation,
    o.RecentPostsCount,
    o.TotalUpVotes,
    o.TotalDownVotes,
    o.CloseActionCount,
    CASE 
        WHEN o.Reputation < 100 THEN 'Newbie'
        WHEN o.Reputation BETWEEN 100 AND 500 THEN 'Intermediate'
        ELSE 'Expert'
    END AS ReputationTier,
    CASE 
        WHEN o.CloseActionCount > 10 THEN 'Frequent Closer'
        ELSE 'Infrequent Closer'
    END AS CloserStatus
FROM 
    OverallStats o
ORDER BY 
    o.Reputation DESC, o.RecentPostsCount DESC, o.TotalUpVotes DESC;
