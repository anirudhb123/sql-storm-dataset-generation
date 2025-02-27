WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
), FilteredPosts AS (
    SELECT 
        rp.*,
        u.DisplayName AS UserDisplayName,
        u.Reputation,
        CASE 
            WHEN u.Reputation IS NULL THEN 'No Reputation'
            WHEN u.Reputation < 100 THEN 'Low Reputation'
            ELSE 'High Reputation'
        END AS ReputationCategory,
        COALESCE(pb.BadgesCount, 0) AS BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgesCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) pb ON u.Id = pb.UserId
    WHERE 
        rp.PostRank = 1
), FinalReport AS (
    SELECT 
        fp.PostId,
        fp.UserDisplayName,
        fp.CreationDate,
        fp.Score,
        fp.CommentCount,
        fp.ReputationCategory,
        fp.BadgeCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        LATERAL (
            SELECT 
                unnest(string_to_array(fp.Tags, '><')) AS TagName
        ) t ON true
    GROUP BY 
        fp.PostId, fp.UserDisplayName, fp.CreationDate, fp.Score, fp.CommentCount, fp.ReputationCategory, fp.BadgeCount
)
SELECT 
    fr.*,
    CASE 
        WHEN fr.BadgeCount = 0 THEN 'No Badges Awarded'
        WHEN fr.BadgeCount > 10 THEN 'Badge Overachiever'
        ELSE 'Moderate Badge User'
    END AS BadgeStatus,
    EXISTS (
        SELECT 1
        FROM Votes v
        WHERE 
            v.PostId = fr.PostId 
            AND v.VoteTypeId IN (2, 3) -- UpMod or DownMod
            AND v.UserId = (
                SELECT MIN(u.Id)
                FROM Users u
                WHERE u.EmailHash IS NOT NULL
            )
    ) AS HasVoteByActiveUser
FROM 
    FinalReport fr
WHERE 
    fr.CommentCount > 2
ORDER BY 
    fr.Score DESC NULLS LAST, fr.CreationDate DESC;

This SQL query involves several advanced constructs:

1. **CTEs (Common Table Expressions)** are used to create a ladder of results, filtering down to the relevant posts and enabling ranking and categorization.
2. **Window functions** such as `ROW_NUMBER` and `COUNT` to rank and count comments on each post within user partitions.
3. **Coalesce and conditional logic** is used to categorize users based on their reputation and badge counts.
4. **LATERAL join with unnest** to break down tags from a string array that simulates certain SQL behaviors (usually outside norm).
5. **Predicate logic** in the final selection to filter based on complex criteria.
6. **Subqueries** to ensure certain conditions about votes and engagement by "active" users with non-null identifiers.
7. The result set is filtered to showcase posts with certain characteristics while handling potential NULL values in multiple ways. 

This approach tests performance through various operations, allowing benchmarking across join types, subqueries, groupings, ordering criteria, and conditional expressions.
