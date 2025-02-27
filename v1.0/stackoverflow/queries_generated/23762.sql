WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        (SELECT COUNT(b.Id) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 1) AS GoldBadges,
        (SELECT COUNT(b.Id) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 2) AS SilverBadges,
        (SELECT COUNT(b.Id) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
PostActivity AS (
    SELECT 
        PostId,
        COUNT(*) AS ActivityCount,
        MAX(CreationDate) AS LastActivity
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        COALESCE(ua.Reputation, 0) AS UserReputation,
        ua.GoldBadges,
        ua.SilverBadges,
        ua.BronzeBadges,
        ISNULL(pa.ActivityCount, 0) AS ActivityCount,
        rp.ViewCount
    FROM 
        RecentPosts rp
    LEFT JOIN 
        UserReputation ua ON rp.OwnerUserId = ua.UserId
    LEFT JOIN 
        PostActivity pa ON rp.PostId = pa.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.UserReputation,
    pd.GoldBadges,
    pd.SilverBadges,
    pd.BronzeBadges,
    pd.ActivityCount,
    pd.ViewCount,
    CASE 
        WHEN pd.ViewCount > 100 THEN 'Popular' 
        ELSE 'Less Popular' 
    END AS Popularity,
    CASE 
        WHEN pd.UserReputation > 1000 THEN 'Respected User' 
        ELSE 'New User' 
    END AS UserStatus
FROM 
    PostDetails pd
WHERE 
    (pd.UserReputation >= 500 OR pd.ActivityCount > 5)
    AND pd.CreationDate <= NOW() - INTERVAL '7 days'
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC, pd.ActivityCount DESC;

-- Let's add an outer join section for quirky users with many tags
WITH TagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(t.Id) AS TagCount,
        MIN(t.TagName) AS FirstTag
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        p.Id
)
SELECT 
    pd.*, 
    tc.TagCount, 
    tc.FirstTag,
    CASE 
        WHEN tc.TagCount IS NULL THEN 'No Tags'
        WHEN tc.TagCount < 2 THEN 'Single Tag'
        ELSE 'Multiple Tags'
    END AS TagDescription
FROM 
    PostDetails pd
LEFT JOIN 
    TagCounts tc ON pd.PostId = tc.PostId
WHERE 
    pd.UserReputation > (SELECT AVG(Reputation) FROM Users) 
ORDER BY 
    pd.CreationDate DESC, tc.TagCount DESC;

-- Here we also have a bizarre irregular semantics part, accommodating unusual reputation cases
SELECT 
    userId,
    Reputation,
    CASE 
        WHEN Reputation IS NULL THEN 'Unknown Reputation'
        WHEN Reputation < 0 THEN 'Negative Reputation'
        ELSE 'Valid Reputation'
    END AS ReputationStatus
FROM 
    Users
WHERE 
    UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE PostTypeId = 1) 
AND 
    (Reputation IS NULL OR Reputation < 0 OR Reputation > 10000);
This SQL query illustrates a complex interaction of various SQL constructs, including `WITH` clauses (Common Table Expressions), outer joins, correlated subqueries, window functions, computed columns using case statements, and complicated filtering logic, emphasizing peculiar edge cases.
