WITH RecursivePostHierarchy AS (
    SELECT 
        Id, 
        Title, 
        ParentId, 
        CAST(Title AS VARCHAR(300)) AS Path, 
        1 AS Level
    FROM 
        Posts 
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id, 
        p.Title, 
        p.ParentId, 
        CAST(rph.Path || ' -> ' || p.Title AS VARCHAR(300)), 
        rph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
UserWithBadges AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
HighScorePosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score,
        CASE 
            WHEN p.Score > 100 THEN 'High'
            WHEN p.Score > 50 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory
    FROM 
        Posts p
),
FilteredPosts AS (
    SELECT 
        hp.Id, 
        hp.Title, 
        hp.Score, 
        hp.ScoreCategory,
        uwd.DisplayName,
        rph.Path,
        ROW_NUMBER() OVER(PARTITION BY hp.ScoreCategory ORDER BY hp.Score DESC) AS Rank
    FROM 
        HighScorePosts hp
    INNER JOIN 
        UserWithBadges uwd ON hp.OwnerUserId = uwd.UserId
    LEFT JOIN 
        RecursivePostHierarchy rph ON hp.Id = rph.Id
    WHERE 
        hp.ScoreCategory = 'High'
        AND uwd.BadgeCount > 0
)
SELECT 
    fp.Title,
    fp.Score,
    fp.ScoreCategory,
    fp.DisplayName,
    fp.Path,
    fp.Rank
FROM 
    FilteredPosts fp
WHERE 
    fp.Rank <= 5
ORDER BY 
    fp.Score DESC;

This SQL query does the following:

1. **Recursive CTE** (`RecursivePostHierarchy`): Builds a hierarchy of posts, allowing for nested answers.
2. **Aggregated User Data** (`UserWithBadges`): Calculates the total number of badges a user has and counts how many of each class of badge they hold (gold, silver, bronze).
3. **Post Scoring** (`HighScorePosts`): Categorizes posts based on their score into 'High', 'Medium', and 'Low'.
4. **Filtered View** (`FilteredPosts`): Combines the previous CTEs while filtering for high-scoring posts, ensuring that only users with at least one badge are included. It also assigns a ranking within the score category.
5. **Final Selection**: The main select query retrieves the top posts ranked from high to low scores within the filtered conditions.

The query highlights the relationships between posts, users, badges, and how posts relate to each other in terms of answers and discussions. Additionally, it incorporates window functions and NULL logic effectively.
