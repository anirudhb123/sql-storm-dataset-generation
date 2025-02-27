WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        MAX(b.Class) AS MaxBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph 
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),

PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),

FinalStats AS (
    SELECT 
        p.PostId,
        p.Title,
        p.Score,
        up.UpVotes,
        down.DownVotes,
        COALESCE(cb.CloseCount, 0) AS CloseCount,
        COALESCE(u.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(u.MaxBadgeClass, 0) AS UserMaxBadgeClass,
        p.RecentPostRank
    FROM 
        RankedPosts p
    LEFT JOIN 
        PostVoteStats up ON p.PostId = up.PostId
    LEFT JOIN 
        PostVoteStats down ON p.PostId = down.PostId
    LEFT JOIN 
        ClosedPosts cb ON p.PostId = cb.PostId
    LEFT JOIN 
        UserBadges u ON p.PostId IN (SELECT ParentId FROM Posts WHERE OwnerUserId = u.UserId)
)

SELECT 
    f.PostId,
    f.Title,
    f.Score,
    f.UpVotes,
    f.DownVotes,
    f.CloseCount,
    f.UserBadgeCount,
    f.UserMaxBadgeClass,
    CASE 
        WHEN f.UpVotes > f.DownVotes THEN 'Positive' 
        WHEN f.UpVotes < f.DownVotes THEN 'Negative' 
        ELSE 'Neutral' 
    END AS Sentiment
FROM 
    FinalStats f
WHERE 
    f.RecentPostRank <= 5 
    AND f.UserBadgeCount > 0 
ORDER BY 
    f.Score DESC NULLS LAST, 
    f.CloseCount DESC;

