WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(pb.BadgeCount, 0) AS BadgeCount,
        COALESCE(pp.UpVotes, 0) AS UpVotes,
        COALESCE(pp.DownVotes, 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        UserBadges pb ON u.Id = pb.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostVoteCounts pp ON p.Id = pp.PostId
    GROUP BY 
        u.Id
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.BadgeCount,
    up.UpVotes,
    up.DownVotes,
    up.PostCount,
    up.TotalViews,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore
FROM 
    UserPostStats up
LEFT JOIN 
    RankedPosts rp ON up.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
WHERE 
    up.BadgeCount > 0
ORDER BY 
    up.TotalViews DESC
LIMIT 10;

This SQL query generates a detailed report showcasing the top-performing users based on their accumulated badge counts, upvotes, downvotes, total posts made, and overall views of their posts. The query utilizes multiple CTEs, including a ranking system to identify the top posts for each type, aggregated vote counts for the posts owned by users, and a final selection to bring together user information along with their top post details. It also incorporates outer joins, complex aggregations, and filtering conditions to provide insightful analytics based on the performance metrics defined in the schema.
