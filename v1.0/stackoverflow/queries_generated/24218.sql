WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        COALESCE((
            SELECT COUNT(DISTINCT c.Id)
            FROM Comments c
            WHERE c.PostId = p.Id
        ), 0) AS TotalComments,
        ARRAY_AGG(DISTINCT t.TagName) FILTER (WHERE t.TagName IS NOT NULL) AS Tags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name, p.Title, p.CreationDate, p.ViewCount
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.TotalComments,
        rp.Tags,
        CASE 
            WHEN rp.RankByScore <= 5 THEN 'Top Post'
            WHEN rp.TotalComments > 0 THEN 'Active Discussion'
            ELSE 'Less Popular'
        END AS PostCategory
    FROM 
        RankedPosts rp
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(b.Class) AS TotalBadgeClass,
        COUNT(v.Id) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '2 years'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.TotalComments,
    pd.Tags,
    pd.PostCategory,
    ua.DisplayName AS UserDisplayName,
    ua.PostCount,
    ua.TotalBadgeClass,
    ua.VoteCount
FROM 
    PostDetails pd
FULL OUTER JOIN 
    UserActivity ua ON pd.PostId IS NULL OR pd.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ua.UserId)
WHERE 
    (ua.VoteCount > 10 OR pd.ViewCount > 100) AND 
    (ua.PostCount IS NULL OR ua.PostCount > 0)
ORDER BY 
    pd.CreationDate DESC NULLS FIRST,
    ua.VoteCount DESC NULLS LAST
LIMIT 100;

This query accomplishes the following:
- Utilizes Common Table Expressions (CTEs) for both ranked posts and user activities.
- Implements window functions for ranking posts based on their score.
- Aggregates tags using `ARRAY_AGG` with a filtering clause to handle NULLs.
- Applies a complex CASE statement to categorize posts according to their engagement.
- Employs a FULL OUTER JOIN to gather both posts and user activities in one result set, ensuring that it includes all posts and all users who have been active.
- Applies intricate predicates in the `WHERE` clause to filter the data based on the defined conditions for posts and users.
- Orders results based on a combination of creation dates and user engagement metrics while correctly handling NULL values.
