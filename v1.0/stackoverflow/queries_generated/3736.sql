WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank 
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph 
    JOIN 
        CloseReasonTypes cr ON ph.Comment::INT = cr.Id 
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
)
SELECT 
    up.DisplayName,
    up.TotalBadges,
    up.TotalUpVotes,
    up.TotalDownVotes,
    up.AverageReputation,
    rp.Title,
    rp.PostId,
    rp.CreationDate,
    rp.ViewCount,
    COALESCE(cpr.CloseReasons, 'Not Closed') AS CloseReasons,
    COUNT(DISTINCT vl.Id) AS VoteCount,
    CASE 
        WHEN COUNT(DISTINCT vl.Id) > 0 THEN 'Voted'
        ELSE 'Not Voted'
    END AS VoteStatus
FROM 
    UserStats up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    Votes vl ON vl.PostId = rp.PostId
LEFT JOIN 
    ClosedPostReasons cpr ON cpr.PostId = rp.PostId
WHERE 
    rp.UserPostRank <= 5
GROUP BY 
    up.UserId, up.DisplayName, up.TotalBadges, up.TotalUpVotes, up.TotalDownVotes, up.AverageReputation, rp.Title, rp.PostId, rp.CreationDate, rp.ViewCount, cpr.CloseReasons
ORDER BY 
    up.TotalBadges DESC, rp.ViewCount DESC;
