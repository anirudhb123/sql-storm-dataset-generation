
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(COUNT(a.Id) AS AnswerCount, 0) 
        AS AnswerCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.CreationDate > DATEADD(DAY, -30, '2024-10-01')
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.Tags, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.Tags,
        ur.Reputation,
        ur.BadgeCount,
        rp.AnswerCount,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC) AS GlobalRank
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.CreationDate,
    ps.Tags,
    ps.Reputation,
    ps.BadgeCount,
    ps.AnswerCount,
    ps.GlobalRank
FROM 
    PostStatistics ps
WHERE 
    ps.GlobalRank <= 10
ORDER BY 
    ps.GlobalRank;
