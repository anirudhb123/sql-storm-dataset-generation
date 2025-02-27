WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        CASE 
            WHEN COUNT(b.Id) > 10 THEN 'Gold'
            WHEN COUNT(b.Id) > 5 THEN 'Silver'
            ELSE 'Bronze'
        END AS BadgeLevel
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteCounts AS (
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
)
SELECT 
    u.DisplayName,
    rb.BadgeLevel,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(pvc.UpVotes) AS TotalUpVotes,
    SUM(pvc.DownVotes) AS TotalDownVotes,
    AVG(rp.Score) AS AvgScore,
    AVG(rp.ViewCount) AS AvgViewCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Users u
JOIN 
    UserBadges rb ON u.Id = rb.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId 
LEFT JOIN 
    PostVoteCounts pvc ON rp.PostId = pvc.PostId
LEFT JOIN 
    UNNEST(STRING_TO_ARRAY((
        SELECT 
            DISTINCT p.Tags 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = u.Id
    ), ',')) AS tag(id) ON TRIM(tag.id) = ANY(STRING_TO_ARRAY(rp.Tags, ','))
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id,
    rb.BadgeLevel
HAVING 
    COUNT(DISTINCT rp.PostId) > 5 
ORDER BY 
    AvgScore DESC, 
    TotalPosts DESC 
LIMIT 10
OFFSET 0;

This query does the following:
1. **Common Table Expressions (CTEs)** to aggregate user posts, badges, and votes.
2. **Window functions** (`ROW_NUMBER()`) to rank posts per user by score.
3. **Complex predicates** that filter users based on reputation and count of posts.
4. **String Aggregation** to collect tags across posts.
5. **NULL handling** with LEFT JOINs to account for potential absence of votes or badges.
6. **HAVING clause** to ensure returning users with a significant contribution to the platform. 
7. **Dual Aggregation** to get averages for scores and view counts per user.

This showcases various SQL features as specified, encapsulating performance benchmarking complexity while adhering to the provided database schema.
