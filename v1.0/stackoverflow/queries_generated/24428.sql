WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS IsClosed,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(v.BountyAmount) AS AvgBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.CreationDate >= CURRENT_DATE - INTERVAL '2 years'
    GROUP BY 
        u.Id, u.DisplayName
),

PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS TagPopularity
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE 
        p.ViewCount > 100
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(*) > 5
)

SELECT 
    up.UserId,
    up.DisplayName,
    up.PostCount,
    COALESCE(ARRAY_AGG(DISTINCT rp.TagsArray), '{}') AS Tags,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    CASE 
        WHEN rp.IsClosed = 1 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    pt.TagName AS PopularTag,
    pt.TagPopularity
FROM 
    UserStats up
LEFT JOIN 
    RankedPosts rp ON up.UserId = (SELECT OwnerUserId FROM Posts where Id = rp.PostId LIMIT 1)
LEFT JOIN 
    PopularTags pt ON pt.TagName = ANY(rp.TagsArray)
WHERE 
    up.PostCount > 5
GROUP BY 
    up.UserId, up.DisplayName, rp.Title, rp.CreationDate, rp.ViewCount, rp.IsClosed, pt.TagName, pt.TagPopularity
ORDER BY 
    up.PostCount DESC, rp.ViewCount DESC
LIMIT 100;

This SQL query captures a complex scenario involving:

1. **Common Table Expressions (CTEs)** to encapsulate logic: `RankedPosts` to rank posts per user, `UserStats` to summarize user data, and `PopularTags` to identify frequently used tags among posts.
2. **Window functions** like `ROW_NUMBER()` for sorting posts by creation date and `MAX()` to identify closed posts.
3. **Outer joins** to ensure users without posts and posts without votes are included.
4. **Aggregation** to compile a list of tags used by each post while taking into account duplicated votes and tag popularity.
5. **Unusual logic** by introducing predicates within the `HAVING` clause to filter results based on user activity, like checking for opened or closed statuses.
6. A **NULL handling** via `COALESCE` to manage cases where there are no related tags.
7. Order by multiple criteria, including user post count and post view count.

This intricate query serves both analytic and performance benchmarking purposes, showcasing SQL's advanced capabilities and nuances.
