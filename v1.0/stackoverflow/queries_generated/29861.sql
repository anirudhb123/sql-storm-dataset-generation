WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank,
        STRING_AGG(t.TagName, ', ') AS TagList
    FROM 
        Posts p
    JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        p.PostTypeId = 1  -- Considering only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.OwnerUserId
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(c.Id) AS TotalComments,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id 
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ra.PostId,
    ra.Title,
    ra.Body,
    ra.CreationDate,
    ra.ViewCount,
    ra.Rank,
    ra.TagList,
    ua.DisplayName,
    ua.TotalBounty,
    ua.TotalComments,
    ua.TotalBadges
FROM 
    RankedPosts ra
JOIN 
    UserActivity ua ON ra.OwnerUserId = ua.UserId
WHERE 
    ra.Rank <= 5  -- Top 5 posts per user
ORDER BY 
    ra.ViewCount DESC, ua.TotalBounty DESC;

This SQL query identifies the top 5 most viewed questions from the "Posts" table, ranked by view count for each user. It also aggregates and combines related tags for those posts while joining user activity metrics such as total bounties, total comments, and total badges for each user who authored a question. The final output is organized by view count and total bounty to promote the most engaged and recognized users and their contributions.
