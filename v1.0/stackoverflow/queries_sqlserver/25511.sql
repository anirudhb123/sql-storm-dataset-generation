
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        STRING_SPLIT(p.Tags, '><') AS tag ON 1=1
    LEFT JOIN 
        Tags t ON tag.value = t.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.ViewCount, p.Score, p.CreationDate
),

RecentUserVotes AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY
    GROUP BY 
        v.UserId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.Score,
    rp.Tags,
    u.Reputation AS OwnerReputation,
    ISNULL(rv.VoteCount, 0) AS RecentVoteCount,
    ISNULL(rv.UpVotes, 0) AS RecentUpVotes,
    ISNULL(rv.DownVotes, 0) AS RecentDownVotes
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerDisplayName = u.DisplayName
LEFT JOIN 
    RecentUserVotes rv ON u.Id = rv.UserId
WHERE 
    rp.PostRank <= 3 
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC;
