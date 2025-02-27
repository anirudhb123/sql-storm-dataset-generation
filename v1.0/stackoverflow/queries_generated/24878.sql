WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
ClosePostCounts AS (
    SELECT 
        ph.UserId,
        COUNT(DISTINCT ph.PostId) AS ClosePostCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.UserId
)
SELECT 
    u.DisplayName,
    ua.Reputation,
    COALESCE(rp.RankScore, 0) AS TopPostRankScore,
    ua.PostCount,
    ua.UpVotes,
    ua.DownVotes,
    COALESCE(cpc.ClosePostCount, 0) AS ClosePostsHandled,
    CASE 
        WHEN a.Reputation >= 5000 THEN 'Expert'
        WHEN a.Reputation BETWEEN 1000 AND 4999 THEN 'Experienced'
        ELSE 'Novice'
    END AS UserStatus
FROM 
    Users u
JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.RankScore <= 5
LEFT JOIN 
    ClosePostCounts cpc ON u.Id = cpc.UserId
WHERE 
    (ua.UpVotes - ua.DownVotes) > 0
    AND ua.PostCount >= 1
ORDER BY 
    ua.Reputation DESC, TopPostRankScore DESC NULLS LAST;

This complex SQL query utilizes Common Table Expressions (CTEs) to organize data. It ranks posts by score while filtering posts created within the last year. The activity of users is aggregated, assessing their reputation, and counting their upvotes and downvotes, along with posts they have handled that have been closed. The main query selects various fields, uses CASE statements to classify users based on reputation, and includes a range of LEFT JOINs to ensure comprehensive coverage of user activities. The final result is ordered by reputation and post rank, showing an elaborate integration of various constructs and logical conditions.
