WITH PostTagStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount,
        string_agg(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY (string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pts.UserId,
        pts.Tags,
        pts.CloseCount,
        pts.DeleteCount,
        pts.ViewCount,
        ur.Reputation,
        ur.BadgeCount
    FROM 
        PostTagStats pts
    JOIN 
        Posts p ON p.Id = pts.PostId
    JOIN 
        Users ur ON p.OwnerUserId = ur.Id
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Tags,
    pd.CloseCount,
    pd.DeleteCount,
    pd.ViewCount,
    ur.DisplayName,
    ur.Reputation,
    ur.BadgeCount
FROM 
    PostDetails pd
JOIN 
    Users ur ON pd.UserId = ur.Id
ORDER BY 
    pd.CloseCount DESC, pd.DeleteCount DESC, pd.ViewCount DESC
LIMIT 50;
