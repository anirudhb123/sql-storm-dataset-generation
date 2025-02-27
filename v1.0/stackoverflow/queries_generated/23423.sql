WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostStats AS (
    SELECT 
        PostId,
        AVG(Score) OVER (PARTITION BY OwnerUserId) AS AvgScorePerUser,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        PostId
),
UserBadges AS (
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
    p.Title,
    p.Score,
    ps.AvgScorePerUser,
    bs.BadgeCount,
    bs.BadgeNames,
    COALESCE(ps.UpVotes, 0) AS UpVotes,
    COALESCE(ps.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN ps.AvgScorePerUser IS NULL THEN 'No posts'
        WHEN ps.AvgScorePerUser > 10 THEN 'High Performer'
        ELSE 'Needs Improvement'
    END AS PerformanceStatus
FROM 
    RankedPosts p
LEFT JOIN 
    PostStats ps ON p.PostId = ps.PostId
LEFT JOIN 
    UserBadges bs ON p.OwnerUserId = bs.UserId
WHERE 
    p.Rank <= 10  -- Get only the top 10 posts of each type
ORDER BY 
    p.CreateDate DESC,
    p.Score DESC;
