
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
),
ActiveUsers AS (
    SELECT 
        UserId, 
        COUNT(1) AS ActivityCount
    FROM 
        Votes v
    GROUP BY 
        UserId
    HAVING 
        COUNT(1) > 5
),
RecentPostEdits AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        @rownum := IF(@prev_post_id = ph.PostId, @rownum + 1, 1) AS EditOrder,
        @prev_post_id := ph.PostId
    FROM 
        PostHistory ph, (SELECT @rownum := 0, @prev_post_id := NULL) AS r
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) 
    ORDER BY 
        ph.PostId, ph.CreationDate DESC
)
SELECT 
    ups.DisplayName,
    ups.PostCount,
    ups.PositivePosts,
    ups.NegativePosts,
    ups.AvgScore,
    tt.TagName,
    a.ActivityCount,
    CASE
        WHEN a.ActivityCount > 10 THEN 'Highly Active'
        WHEN a.ActivityCount BETWEEN 5 AND 10 THEN 'Moderately Active'
        ELSE 'Low Activity'
    END AS ActivityLevel,
    COUNT(rpe.PostId) AS RecentEditCount
FROM 
    UserPostStats ups
JOIN 
    TopTags tt ON tt.PostCount > 20
JOIN 
    ActiveUsers a ON a.UserId = ups.UserId
LEFT JOIN 
    RecentPostEdits rpe ON rpe.UserId = ups.UserId
GROUP BY 
    ups.UserId, ups.DisplayName, ups.PostCount, ups.PositivePosts, ups.NegativePosts, ups.AvgScore, tt.TagName, a.ActivityCount
ORDER BY 
    ups.PostCount DESC, ups.AvgScore DESC
LIMIT 100;
