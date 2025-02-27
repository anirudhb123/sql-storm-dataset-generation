
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(NULLIF(u.DisplayName, ''), 'Anonymous') AS UserDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score, u.DisplayName
),
PopularTags AS (
    SELECT
        t.TagName,
        COUNT(pt.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.Id) > 10
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        @row_number := IF(@prev_reputation = u.Reputation, @row_number, @row_number + 1) AS ReputationRank,
        @prev_reputation := u.Reputation
    FROM 
        Users u,
        (SELECT @row_number := 0, @prev_reputation := NULL) AS vars
    ORDER BY u.Reputation DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.UserDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    GROUP_CONCAT(pt.TagName) AS AssociatedTags,
    CASE 
        WHEN ur.ReputationRank <= 10 THEN 'Top Contributor'
        WHEN ur.ReputationRank BETWEEN 11 AND 50 THEN 'Veteran Contributor'
        ELSE 'New Contributor'
    END AS ContributorLevel
FROM 
    RecentPosts rp
LEFT JOIN 
    PopularTags pt ON rp.Title LIKE CONCAT('%', pt.TagName, '%')
LEFT JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
GROUP BY 
    rp.PostId, rp.Title, rp.UserDisplayName, rp.CreationDate, rp.Score, rp.CommentCount, ur.ReputationRank
ORDER BY 
    rp.Score DESC, rp.CommentCount DESC
LIMIT 50;
