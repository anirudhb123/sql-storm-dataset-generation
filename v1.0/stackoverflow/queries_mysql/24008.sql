
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByType
    FROM 
        Posts p
    WHERE 
        p.ViewCount IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
PostTagData AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT Id, SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM 
            (SELECT @row := @row + 1 AS n 
             FROM 
                (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers, 
                (SELECT @row := 0) r
            ) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag.TagName
    GROUP BY 
        p.Id
)
SELECT 
    p.PostId,
    p.Title,
    CONCAT(u.DisplayName, ' (Reputation: ', u.Reputation + COALESCE(u.TotalBounties, 0), ')') AS UserProfile,
    p.CreationDate,
    COALESCE(pt.Tags, 'No Tags') AS AssociatedTags,
    CASE 
        WHEN p.RankByType = 1 THEN 'Latest'
        WHEN p.RankByType <= 3 THEN 'Popular'
        ELSE 'Other'
    END AS PostRank
FROM 
    RankedPosts p
LEFT JOIN 
    UserReputation u ON p.OwnerUserId = u.UserId
LEFT JOIN 
    PostTagData pt ON p.PostId = pt.PostId
WHERE 
    p.RankByType <= 10 
    AND (u.Reputation > 1000 OR u.Reputation IS NULL) 
ORDER BY 
    p.CreationDate DESC, 
    u.Reputation DESC
LIMIT 50 OFFSET 0;
