
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
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        STRING_SPLIT(p.Tags, ',') AS tag ON p.Id = p.Id
    JOIN 
        Tags t ON LOWER(LTRIM(RTRIM(tag.value))) = LOWER(t.TagName)
    GROUP BY 
        p.Id
)
SELECT 
    hsp.Title,
    hsp.Score,
    hsp.CreationDate,
    hsp.Reputation,
    hsp.ReputationLevel,
    ISNULL(pt.Tags, 'No Tags') AS Tags,
    hsp.EditCount,
    hsp.LastEditDate
FROM 
    HighScoringPosts hsp
LEFT JOIN 
    PostTags pt ON hsp.PostId = pt.PostId
ORDER BY 
    hsp.Score DESC, hsp.Reputation DESC;
