WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        STRING_AGG(t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank
    FROM Posts p
    JOIN Tags t ON t.Id IN (SELECT unnest(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '>'))::int)
    WHERE p.PostTypeId = 1 -- Only questions
    GROUP BY p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, p.Score
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Score,
        rp.Tags,
        ur.DisplayName AS OwnerName,
        ur.Reputation AS OwnerReputation,
        ur.BadgeCount,
        rp.UserRank
    FROM RankedPosts rp
    JOIN UserReputation ur ON ur.UserId = rp.OwnerUserId
)

SELECT 
    pd.PostId, 
    pd.Title, 
    pd.Body, 
    pd.CreationDate, 
    pd.ViewCount, 
    pd.AnswerCount, 
    pd.Score, 
    pd.Tags,
    pd.OwnerName,
    pd.OwnerReputation,
    pd.BadgeCount,
    CASE 
        WHEN pd.UserRank = 1 THEN 'Most Recent'
        ELSE 'Earlier Post'
    END AS PostRankStatus
FROM PostDetails pd
WHERE pd.OwnerReputation > 500 -- Users with reputation greater than 500
ORDER BY pd.CreationDate DESC
LIMIT 100;
