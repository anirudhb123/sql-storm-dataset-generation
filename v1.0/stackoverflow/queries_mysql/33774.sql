
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation >= 1000 THEN 'High'
            WHEN u.Reputation >= 100 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM 
        Users u
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) 
    GROUP BY 
        ph.PostId
),
HighScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        ur.Reputation,
        ur.ReputationLevel,
        pha.EditCount,
        pha.LastEditDate
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        PostHistoryAggregates pha ON rp.PostId = pha.PostId
    WHERE 
        rp.UserPostRank = 1 
        AND ur.Reputation > 500 
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT 
            p.Id AS PostId, 
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName
         FROM 
            Posts p 
         JOIN 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
             SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
             SELECT 9 UNION ALL SELECT 10) numbers 
         ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1
        ) AS tag ON p.Id = tag.PostId
    JOIN 
        Tags t ON LOWER(tag.TagName) = LOWER(t.TagName)
    GROUP BY 
        p.Id
)
SELECT 
    hsp.Title,
    hsp.Score,
    hsp.CreationDate,
    hsp.Reputation,
    hsp.ReputationLevel,
    COALESCE(pt.Tags, 'No Tags') AS Tags,
    hsp.EditCount,
    hsp.LastEditDate
FROM 
    HighScoringPosts hsp
LEFT JOIN 
    PostTags pt ON hsp.PostId = pt.PostId
ORDER BY 
    hsp.Score DESC, hsp.Reputation DESC;
