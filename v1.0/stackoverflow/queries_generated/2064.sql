WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        h.PostId,
        MIN(h.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory h
    WHERE 
        h.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        h.PostId
)
SELECT 
    up.DisplayName,
    COALESCE(rp.Title, 'No Questions') AS RecentQuestion,
    COALESCE(rp.CreationDate, 'N/A') AS RecentQuestionDate,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.TotalBadges,
    cp.FirstClosedDate
FROM 
    Users up
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    UserStats us ON up.Id = us.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    up.Reputation > 500
ORDER BY 
    us.TotalUpVotes DESC NULLS LAST, 
    us.TotalBadges DESC, 
    up.DisplayName;
